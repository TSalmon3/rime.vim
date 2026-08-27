#ifdef _WIN32
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <cstdlib>
#include <csignal>
#include <cerrno>
#include <cstring>
#include <string>
#include <vector>
#include <map>
#include <unordered_map>
#include <algorithm>
#include <iostream>
#include <filesystem>
#include <chrono>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <thread>
#include <atomic>
#include <mutex>
#if !defined(_SSIZE_T_DEFINED)
#define _SSIZE_T_DEFINED
typedef SSIZE_T ssize_t;  // POSIX 类型，Windows/MSVC 目标下用 SSIZE_T 等价定义
#endif
#else
#include <poll.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#endif

#include <rime_api.h>
#include "3rd/json.hpp"
#include "3rd/spdlog/spdlog.h"
#include "3rd/spdlog/sinks/basic_file_sink.h"
#include "3rd/spdlog/sinks/null_sink.h"

using json = nlohmann::json;

static void log_init() {// {{{
  std::string log_path;
  bool to_file = false;
  const char *env_log = getenv("RIME_LOG");
  if (env_log && *env_log) {
    log_path = env_log;
    to_file = true;
  } else {
#ifdef _WIN32
    const char *local = getenv("LOCALAPPDATA");
    if (local && *local) {
      log_path = std::string(local) + "\\rime-query\\rime.log";
      to_file = true;
    }
#else
    const char *xdg = getenv("XDG_STATE_HOME");
    if (xdg && *xdg) {
      log_path = std::string(xdg) + "/rime-query/rime.log";
      to_file = true;
    } else {
      const char *home = getenv("HOME");
      if (home) {
        log_path = std::string(home) + "/.local/state/rime-query/rime.log";
        to_file = true;
      }
    }
#endif
  }

  std::shared_ptr<spdlog::logger> logger;
  if (to_file) {
    std::filesystem::create_directories(std::filesystem::path(log_path).parent_path());
    logger = spdlog::basic_logger_mt("rime", log_path);
  } else {
    logger = spdlog::null_logger_mt("rime");
  }
  spdlog::set_default_logger(logger);
  spdlog::set_level(spdlog::level::debug);
  spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%l] %v");
  spdlog::flush_on(spdlog::level::debug);
}// }}}

// ---------------------------------------------------------------------------
// Global state
// ---------------------------------------------------------------------------

static volatile std::sig_atomic_t g_should_exit = 0;

static std::string g_deploy_status;

struct Client {
#ifdef _WIN32
  SOCKET sock = INVALID_SOCKET;
  HANDLE stdin_handle = INVALID_HANDLE_VALUE;  // 仅 stdio 模式使用
#else
  int fd = -1;
#endif
  bool is_stdio = false;
  bool dead = false;              // 写失败/对端断开，事件循环统一清扫

  std::string in_buf;

  RimeSessionId session = 0;      // 一连接一 session（ibus-rime 同款模型）
  bool inline_ascii_active = false;
  std::string app_hint;

  // 由通知回调填充、随下一次响应发给前端。
  std::vector<std::pair<std::string, bool>> changed_options;
  bool schema_changed = false;
  std::string schema_id;
  std::string schema_name;

  bool schema_broadcast = false;
};

static std::map<long long, Client> g_clients;
static std::unordered_map<RimeSessionId, Client *> g_session_owner;

#ifndef _WIN32
using ClientKey = int;
#else
using ClientKey = long long;
#endif

static ClientKey client_key(const Client &c) {
#ifdef _WIN32
  return static_cast<ClientKey>(c.sock);
#else
  return c.fd;
#endif
}

#ifdef _WIN32
static BOOL WINAPI console_ctrl_handler(DWORD) { g_should_exit = 1; return TRUE; }
#else
static void on_signal(int) { g_should_exit = 1; }
#endif

static void on_notification(void *, RimeSessionId session_id,
                            const char *message_type,
                            const char *message_value);

static bool read_rime_dirs(const char *&shared_dir, const char *&user_dir);

void rime_init(const char *shared_dir, const char *user_dir) {// {{{
  RIME_STRUCT(RimeTraits, traits);
  traits.shared_data_dir        = shared_dir;
  traits.user_data_dir          = user_dir;
  traits.app_name               = "rime.vim-query";
  traits.distribution_name      = "Rime";
  traits.distribution_code_name = "rime-query";
  traits.distribution_version   = "0.3.0";
  traits.min_log_level          = 3;

  RimeApi *api = rime_get_api();
  api->setup(&traits);
  api->initialize(&traits);
  api->set_notification_handler(on_notification, nullptr);

  if (api->start_maintenance(false)) {
    spdlog::info("deployment started, waiting for it to finish...");
    api->join_maintenance_thread();
    spdlog::info("deployment finished");
  }
}// }}}

static void on_deploy_notification(const char *message_value) {// {{{
  g_deploy_status = message_value;
  spdlog::info("deploy notification: {}", message_value);
}// }}}

// ---------------------------------------------------------------------------
// Notification routing
// ---------------------------------------------------------------------------

static void on_notification(void *, RimeSessionId session_id,
                            const char *message_type,
                            const char *message_value) {// {{{
  if (!message_type || !message_value)
    return;
  if (std::strcmp(message_type, "deploy") == 0) {
    on_deploy_notification(message_value);
    return;
  }
  // option / schema 通知按 session 路由到所属客户端。
  auto it = g_session_owner.find(session_id);
  if (it == g_session_owner.end()) {
    spdlog::warn("notification for unknown session {}, dropped", (long long)session_id);
    return;
  }
  Client *c = it->second;
  if (std::strcmp(message_type, "option") == 0) {
    // 值形如 "ascii_mode"（开）或 "!ascii_mode"（关）。
    std::string name = message_value;
    bool on = name[0] != '!';
    if (!on) name = name.substr(1);
    c->changed_options.emplace_back(name, on);
    spdlog::info("option notification: {}={}", name, on);
  } else if (std::strcmp(message_type, "schema") == 0) {
    // 值形如 "luna_pinyin/Luna Pinyin"：<schema_id>/<schema_name>。
    std::string value = message_value;
    auto slash = value.find('/');
    c->schema_id   = value.substr(0, slash);
    c->schema_name = slash == std::string::npos ? "" : value.substr(slash + 1);
    c->schema_changed = true;
    spdlog::info("schema notification: {}", message_value);
  }
}// }}}

static void clear_key_notifications(Client &c) {// {{{
  c.changed_options.clear();
  c.schema_changed = false;
}// }}}

static void fill_notifications(Client &c, json &resp) {// {{{
  json opts = json::array();
  for (auto &kv : c.changed_options)
    opts.push_back({{"name", kv.first}, {"value", kv.second}});
  resp["changed_options"] = opts;
  // deploy 广播与单键事件取或；广播送达即复位，保证恰好一次。
  bool schema_changed = c.schema_changed || c.schema_broadcast;
  c.schema_broadcast = false;
  resp["schema_changed"]  = schema_changed;
  if (schema_changed) {
    if (!c.schema_id.empty()) {
      resp["schema_id"]   = c.schema_id;
      resp["schema_name"] = c.schema_name;
    } else {
      // deploy 广播等场景：主动取当前方案补齐字段。
      RimeApi *api = rime_get_api();
      char schema_buf[256] = {0};
      if (c.session && api->get_current_schema(c.session, schema_buf, sizeof(schema_buf)))
        resp["schema_id"] = schema_buf;
    }
  }
}// }}}

// ---------------------------------------------------------------------------
// Session management
// ---------------------------------------------------------------------------

static RimeSessionId ensure_session(Client &c) {// {{{
  RimeApi *api = rime_get_api();
  if (c.session && api->find_session(c.session))
    return c.session;
  if (c.session)
    g_session_owner.erase(c.session);  // 维护后失效的旧 session
  c.session = api->create_session();
  if (c.session)
    g_session_owner[c.session] = &c;
  spdlog::info("created new session {} for client {}",
               (long long)c.session, (long long)client_key(c));
  return c.session;
}// }}}

static void destroy_client_session(Client &c) {// {{{
  if (!c.session)
    return;
  g_session_owner.erase(c.session);
  rime_get_api()->destroy_session(c.session);
  c.session = 0;
}// }}}

// ---------------------------------------------------------------------------
// Request handling (shared by stdio and serve modes)
// ---------------------------------------------------------------------------

static std::string fetch_commit(Client &c) {// {{{
  RimeApi *api = rime_get_api();
  RimeSessionId sid = ensure_session(c);

  RIME_STRUCT(RimeCommit, commit);
  std::string committed;
  if (sid && api->get_commit(sid, &commit)) {
    if (commit.text) committed = commit.text;
    api->free_commit(&commit);
  }
  return committed;
}// }}}

static void fill_context(Client &c, json &resp) {// {{{
  RimeApi *api = rime_get_api();
  RimeSessionId sid = ensure_session(c);

  RIME_STRUCT(RimeContext, ctx);
  if (!sid || !api->get_context(sid, &ctx)) {
    resp["candidates"] = json::array();
    resp["comments"]   = json::array();
    resp["preedit"]    = "";
    resp["cursor_pos"] = 0;
    resp["sel_start"]  = 0;
    resp["sel_end"]    = 0;
    resp["page_no"]    = 0;
    resp["highlighted_candidate_index"] = 0;
    resp["has_more"]   = false;
    resp["composing"]  = false;
    return;
  }

  std::vector<std::string> candidates;
  std::vector<std::string> comments;
  for (int i = 0; i < ctx.menu.num_candidates; ++i) {
    candidates.push_back(ctx.menu.candidates[i].text ? ctx.menu.candidates[i].text : "");
    comments.push_back(ctx.menu.candidates[i].comment ? ctx.menu.candidates[i].comment : "");
  }

  std::string preedit = ctx.composition.preedit ? ctx.composition.preedit : "";

  resp["candidates"] = candidates;
  resp["comments"]   = comments;
  resp["preedit"]    = preedit;

  resp["cursor_pos"] = ctx.composition.cursor_pos;
  resp["sel_start"]  = ctx.composition.sel_start;
  resp["sel_end"]    = ctx.composition.sel_end;
  resp["page_no"]    = ctx.menu.page_no;
  resp["highlighted_candidate_index"] = ctx.menu.highlighted_candidate_index;
  resp["has_more"]   = !ctx.menu.is_last_page;
  resp["composing"]  = !preedit.empty();

  // 始终带上当前方案 id，让前端无需额外请求即可同步状态栏方案名。
  char schema_buf[256] = {0};
  if (api->get_current_schema(sid, schema_buf, sizeof(schema_buf)))
    resp["schema_id"] = schema_buf;

  api->free_context(&ctx);
}// }}}

static void finish_inline_ascii(Client &c, json &resp) {// {{{
  if (!c.inline_ascii_active || resp.value("composing", true))
    return;
  c.inline_ascii_active = false;
  RimeApi *api = rime_get_api();
  RimeSessionId sid = ensure_session(c);
  if (sid) api->set_option(sid, "ascii_mode", False);
}// }}}

static void rebuild_all_client_sessions() {// {{{
  for (auto &[key, cli] : g_clients) {
    destroy_client_session(cli);
    cli.inline_ascii_active = false;
    cli.changed_options.clear();
    cli.schema_changed = false;
    ensure_session(cli);
    cli.schema_broadcast = true;
  }
}// }}}

static json handle_request(Client &c, const json &req) {// {{{
  json resp;
  resp["id"] = req.value("id", 0);

  std::string type = req.value("type", "");
  RimeApi *api = rime_get_api();

  // --- ping ---
  if (type == "ping") {
    if (req.contains("app")) c.app_hint = req.value("app", std::string());
    resp["ok"] = true;
    return resp;
  }

  // --- quit ---
  if (type == "quit") {
    resp["ok"] = true;
    g_should_exit = 1;
    return resp;
  }

  // --- warmup ---
  if (type == "warmup") {
    RimeSessionId sid = ensure_session(c);
    if (sid) {
      api->process_key(sid, 'a', 0);
      api->clear_composition(sid);
    }
    resp["ok"] = true;
    return resp;
  }

  if (type == "key") {
    if (!req.contains("keycode")) {
      resp["ok"]    = false;
      resp["error"] = "key requires 'keycode'";
      return resp;
    }
    int keycode = req.value("keycode", 0);
    int mask    = req.value("mask", 0);

    clear_key_notifications(c);
    RimeSessionId sid = ensure_session(c);
    Bool accepted = api->process_key(sid, keycode, mask);

    resp["ok"]        = true;
    resp["accepted"]  = (bool)accepted;
    resp["committed"] = fetch_commit(c);
    fill_context(c, resp);
    finish_inline_ascii(c, resp);
    fill_notifications(c, resp);
    return resp;
  }

  if (type == "select") {
    int index = req.value("index", 0);
    clear_key_notifications(c);
    RimeSessionId sid = ensure_session(c);
    api->select_candidate_on_current_page(sid, index);

    resp["ok"]        = true;
    resp["committed"] = fetch_commit(c);
    fill_context(c, resp);
    finish_inline_ascii(c, resp);
    fill_notifications(c, resp);
    return resp;
  }

  // --- get_input ---
  if (type == "get_input") {
    RimeSessionId sid = ensure_session(c);
    const char *input = sid ? api->get_input(sid) : nullptr;

    resp["ok"]    = true;
    resp["input"] = input ? input : "";
    fill_context(c, resp);
    return resp;
  }

  // --- commit_composition ---
  if (type == "commit_composition") {
    clear_key_notifications(c);
    RimeSessionId sid = ensure_session(c);
    if (sid) api->commit_composition(sid);

    resp["ok"]        = true;
    resp["committed"] = fetch_commit(c);
    fill_context(c, resp);
    finish_inline_ascii(c, resp);
    fill_notifications(c, resp);
    return resp;
  }

  // --- switch_ascii_mode ---
  if (type == "switch_ascii_mode") {
    std::string style = req.value("style", "");
    const std::vector<std::string> valid_styles = {
        "commit_code", "commit_text", "clear", "inline_ascii",
        "set_ascii_mode", "unset_ascii_mode"};
    if (std::find(valid_styles.begin(), valid_styles.end(), style) == valid_styles.end()) {
      resp["ok"]    = false;
      resp["error"] = "invalid style: " + style;
      return resp;
    }

    clear_key_notifications(c);
    RimeSessionId sid = ensure_session(c);

    Bool old_mode = sid ? api->get_option(sid, "ascii_mode") : False;
    Bool new_mode = style == "set_ascii_mode"   ? True
                  : style == "unset_ascii_mode" ? False
                  : (old_mode ? False : True);

    bool composing = false;
    int  highlighted = 0, num_candidates = 0;
    RIME_STRUCT(RimeContext, ctx);
    if (sid && api->get_context(sid, &ctx)) {
        composing = ctx.composition.preedit && *ctx.composition.preedit;
        highlighted   = ctx.menu.highlighted_candidate_index;
        num_candidates = ctx.menu.num_candidates;
        api->free_context(&ctx);
    }

    std::string committed;
    if (new_mode != old_mode) {
        if (composing) {
            if (style == "commit_code" ||
                (style == "commit_text" && num_candidates == 0)) {
                const char *input = api->get_input(sid);
                if (input) committed = input;
                api->clear_composition(sid);
            } else if (style == "commit_text") {
                api->select_candidate_on_current_page(sid, (size_t)highlighted);
                committed = fetch_commit(c);
            } else if (style == "clear" || style == "set_ascii_mode" ||
                       style == "unset_ascii_mode") {
                api->clear_composition(sid);
            } else if (style == "inline_ascii") {
                c.inline_ascii_active = new_mode;
            }
        }
        api->set_option(sid, "ascii_mode", new_mode);
        // 显式切回中文时，inline 临时态随之终止，避免 finish_inline_ascii
        // 重复发一次同样的 option 通知。
        if (!new_mode)
            c.inline_ascii_active = false;
    }

    resp["ok"]           = true;
    resp["style"]        = style;
    resp["committed"]    = committed;
    resp["inline_ascii"] = c.inline_ascii_active;
    fill_context(c, resp);
    finish_inline_ascii(c, resp);
    fill_notifications(c, resp);
    return resp;
  }

  if (type == "reset") {
    clear_key_notifications(c);
    RimeSessionId sid = ensure_session(c);
    if (sid) api->clear_composition(sid);
    resp["ok"] = true;
    fill_context(c, resp);
    finish_inline_ascii(c, resp);
    fill_notifications(c, resp);
    return resp;
  }

  // --- deploy ---
  // 等价于 Squirrel/Weasel 的「重新部署」：全局独占跑一遍完整维护任务，
  // 期间销毁并重建所有客户端的会话，并向它们广播方案变更。
  if (type == "deploy") {
    destroy_client_session(c);
    c.inline_ascii_active = false;
    g_deploy_status.clear();
    Bool started = api->start_maintenance(true);
    if (!started) {
      resp["ok"]             = false;
      resp["error"]          = "maintenance already in progress";
      resp["deploy_status"]  = g_deploy_status;
      return resp;
    }
    api->join_maintenance_thread();
    if (g_deploy_status.empty())
      g_deploy_status = "success";  // 未收到失败通知即视为成功
    resp["ok"]            = g_deploy_status == "success";
    resp["deploy_status"] = g_deploy_status;
    if (g_deploy_status != "success") {
      resp["error"] = "deploy failed, check the rime log for details";
    } else {
      rebuild_all_client_sessions();
    }
    return resp;
  }

  // --- sync ---
  // 双向同步用户词库：合并 sync/<installation_id>/schema.userdb.txt 备份。
  // RimeSyncUserData 只是调度任务并异步启动 maintenance，必须 join 等它跑完，
  // 否则 user_dict_sync（最后一步，负责导出 *.userdb.txt）会被打断。
  if (type == "sync") {
    g_deploy_status.clear();
    api->sync_user_data();
    api->join_maintenance_thread();
    if (g_deploy_status.empty())
      g_deploy_status = "success";  // 未收到失败通知即视为成功
    resp["ok"]            = g_deploy_status == "success";
    resp["deploy_status"] = g_deploy_status;
    if (g_deploy_status != "success") {
      resp["error"] = "sync failed, check the rime log for details";
    }
    return resp;
  }

  // --- toggle_option ---
  if (type == "toggle_option") {
    std::string option = req.value("option", "");
    if (option.empty()) {
      resp["ok"]    = false;
      resp["error"] = "option is required";
      return resp;
    }
    clear_key_notifications(c);
    RimeSessionId sid = ensure_session(c);
    if (!sid) {
      resp["ok"]    = false;
      resp["error"] = "no active session";
      return resp;
    }
    Bool current   = api->get_option(sid, option.c_str());
    Bool new_value = current ? False : True;
    api->set_option(sid, option.c_str(), new_value);

    if (option == "ascii_mode" && !new_value)
      c.inline_ascii_active = false;

    resp["ok"]     = true;
    resp["option"] = option;
    resp["value"]  = (bool)new_value;
    return resp;
  }

  if (type == "set_option") {
    std::string option = req.value("option", "");
    if (option.empty()) {
      resp["ok"]    = false;
      resp["error"] = "option is required";
      return resp;
    }
    clear_key_notifications(c);
    RimeSessionId sid = ensure_session(c);
    if (!sid) {
      resp["ok"]    = false;
      resp["error"] = "no active session";
      return resp;
    }
    Bool value = req.value("value", false) ? True : False;
    api->set_option(sid, option.c_str(), value);

    if (option == "ascii_mode" && !value)
      c.inline_ascii_active = false;

    resp["ok"]     = true;
    resp["option"] = option;
    resp["value"]  = (bool)value;
    return resp;
  }

  if (type == "get_option") {
    std::string option = req.value("option", "");
    if (option.empty()) {
      resp["ok"]    = false;
      resp["error"] = "option is required";
      return resp;
    }
    RimeSessionId sid = ensure_session(c);
    if (!sid) {
      resp["ok"]    = false;
      resp["error"] = "no active session";
      return resp;
    }
    Bool current = api->get_option(sid, option.c_str());

    resp["ok"]     = true;
    resp["option"] = option;
    resp["value"]  = (bool)current;
    return resp;
  }

  resp["ok"]    = false;
  resp["error"] = "unknown type: " + type;
  return resp;
}// }}}

// ---------------------------------------------------------------------------
// Line dispatch & output
// ---------------------------------------------------------------------------

static void write_stdout_line(const std::string &line) {// {{{
  std::cout << line << "\n";
  std::cout.flush();
}// }}}

#ifdef _WIN32
static bool send_line_to_client(Client &c, const std::string &line) {// {{{
  std::string data = line + "\n";
  size_t off = 0;
  while (off < data.size()) {
    int n = ::send(c.sock, data.data() + off,
                   (int)(data.size() - off), 0);
    if (n == SOCKET_ERROR || n == 0) {
      spdlog::warn("send to client failed: {}", WSAGetLastError());
      c.dead = true;
      return false;
    }
    off += static_cast<size_t>(n);
  }
  return true;
}// }}}
#else
static bool send_line_to_client(Client &c, const std::string &line) {// {{{
  std::string data = line + "\n";
  size_t off = 0;
  while (off < data.size()) {
    ssize_t n = ::write(c.fd, data.data() + off, data.size() - off);
    if (n < 0) {
      if (errno == EINTR) continue;
      spdlog::warn("write to client {} failed: {}, marking dead",
                   (long long)c.fd, strerror(errno));
      c.dead = true;
      return false;
    }
    off += static_cast<size_t>(n);
  }
  return true;
}// }}}
#endif

static void send_ready_greeting(Client &c) {// {{{
  json ready;
  ready["id"]   = 0;
  ready["ok"]   = true;
  ready["type"] = "ready";
  send_line_to_client(c, ready.dump());
}// }}}

static void handle_line(Client &c, const std::string &line) {// {{{
  try {
    json req  = json::parse(line);
    spdlog::debug(">> [{}] {}", (long long)client_key(c), line);
    json resp = handle_request(c, req);
    std::string out = resp.dump();
    spdlog::debug("<< [{}] {}", (long long)client_key(c), out);
    if (c.is_stdio)
      write_stdout_line(out);
    else
      send_line_to_client(c, out);
  } catch (const json::exception &e) {
    json err;
    err["id"]    = 0;
    err["ok"]    = false;
    err["error"] = std::string("JSON parse error: ") + e.what();
    if (c.is_stdio)
      write_stdout_line(err.dump());
    else
      send_line_to_client(c, err.dump());
  }
}// }}}

static void feed_bytes(Client &c, const char *data, size_t n) {// {{{
  c.in_buf.append(data, n);
  size_t pos;
  while (!c.dead &&
         (pos = c.in_buf.find('\n')) != std::string::npos) {
    std::string line = c.in_buf.substr(0, pos);
    c.in_buf.erase(0, pos + 1);
    if (line.empty()) continue;
    handle_line(c, line);
  }
}// }}}

// ---------------------------------------------------------------------------
// Legacy stdio mode
// ---------------------------------------------------------------------------

// 返回 1=有数据可读，0=超时（调用方应重查退出标志），-1=EOF/错误。
static int wait_stdin_ready(int timeout_ms) {// {{{
#ifdef _WIN32
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  DWORD avail = 0;
  if (!PeekNamedPipe(h, nullptr, 0, nullptr, &avail, nullptr))
    return -1;  // 管道已断开，视同 EOF
  if (avail > 0)
    return 1;
  Sleep(timeout_ms);
  return 0;
#else
  struct pollfd pfd;
  pfd.fd      = STDIN_FILENO;
  pfd.events  = POLLIN;
  int r = poll(&pfd, 1, timeout_ms);
  if (r < 0)
    return errno == EINTR ? 0 : -1;
  if (r == 0)
    return 0;
  if (pfd.revents & POLLIN)
    return 1;
  return -1;
#endif
}// }}}

// 返回读取字节数，0 或负数表示 EOF/错误。
static ssize_t read_stdin(char *buf, size_t n) {// {{{
#ifdef _WIN32
  DWORD got = 0;
  if (!ReadFile(GetStdHandle(STD_INPUT_HANDLE), buf, static_cast<DWORD>(n),
                &got, nullptr))
    return 0;
  return static_cast<ssize_t>(got);
#else
  return read(STDIN_FILENO, buf, n);
#endif
}// }}}

static int run_stdio() {// {{{
  Client stdio_client;
  stdio_client.is_stdio = true;
#ifdef _WIN32
  stdio_client.stdin_handle = GetStdHandle(STD_INPUT_HANDLE);
#else
  stdio_client.fd = STDIN_FILENO;
#endif

  std::string pending;
  char buf[4096];
  while (!g_should_exit) {
    int ready = wait_stdin_ready(100);
    if (ready < 0) break;      // EOF / 管道断开
    if (ready == 0) continue;  // 超时，回查退出标志
    ssize_t n = read_stdin(buf, sizeof(buf));
    if (n <= 0) break;

    pending.append(buf, static_cast<size_t>(n));
    size_t pos;
    while (!g_should_exit &&
           (pos = pending.find('\n')) != std::string::npos) {
      std::string line = pending.substr(0, pos);
      pending.erase(0, pos + 1);
      if (line.empty()) continue;
      handle_line(stdio_client, line);
    }
  }

  destroy_client_session(stdio_client);
  return 0;
}// }}}

// ---------------------------------------------------------------------------
// Serve mode: Unix domain socket
// ---------------------------------------------------------------------------

#ifndef _WIN32

static std::string default_endpoint() {// {{{
  const char *env = getenv("RIME_QUERY_SOCKET");
  if (env && *env) return env;
  namespace fs = std::filesystem;
  const char *xdg = getenv("XDG_RUNTIME_DIR");
  if (xdg && *xdg) return std::string(xdg) + "/rime-query.sock";
  const char *home = getenv("HOME");
  if (home && *home) {
    std::error_code ec;
    fs::create_directories(std::string(home) + "/.cache", ec);
    return std::string(home) + "/.cache/rime-query.sock";
  }
  return "/tmp/rime-query.sock";
}// }}}

static bool try_connect_existing(const std::string &path) {// {{{
  int fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd < 0) return false;
  sockaddr_un addr{};
  addr.sun_family = AF_UNIX;
  std::strncpy(addr.sun_path, path.c_str(), sizeof(addr.sun_path) - 1);
  bool ok = ::connect(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) == 0;
  ::close(fd);
  return ok;
}// }}}

static int open_unix_listener(const std::string &path) {// {{{
  if (try_connect_existing(path)) {
    spdlog::info("another rime-query daemon is already serving '{}'", path);
    return -2;
  }

  int fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd < 0) {
    spdlog::error("socket() failed: {}", strerror(errno));
    return -1;
  }

  sockaddr_un addr{};
  addr.sun_family = AF_UNIX;
  std::strncpy(addr.sun_path, path.c_str(), sizeof(addr.sun_path) - 1);

  if (::bind(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) < 0) {
    if (errno == EADDRINUSE) {
      if (try_connect_existing(path)) {
        ::close(fd);
        spdlog::info("another rime-query daemon is already serving '{}'", path);
        return -2;
      }
      spdlog::warn("stale socket file '{}', taking over", path);
      ::unlink(path.c_str());
      if (::bind(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) < 0) {
        spdlog::error("bind('{}') after cleanup failed: {}", path, strerror(errno));
        ::close(fd);
        return -1;
      }
    } else {
      spdlog::error("bind('{}') failed: {}", path, strerror(errno));
      ::close(fd);
      return -1;
    }
  }
  if (::listen(fd, 16) < 0) {
    spdlog::error("listen() failed: {}", strerror(errno));
    ::close(fd);
    return -1;
  }
  return fd;
}// }}}

static int run_server_unix(const std::string &endpoint, long idle_exit_ms) {// {{{
  int listen_fd = open_unix_listener(endpoint);
  if (listen_fd == -2) return 0;   // 已有实例，安静退出
  if (listen_fd < 0) return 1; // 失败退出

  const char *shared_dir = nullptr;
  const char *user_dir   = nullptr;

  if (!read_rime_dirs(shared_dir, user_dir)) {
    ::close(listen_fd);
    ::unlink(endpoint.c_str());
    return 1;
  }

  rime_init(shared_dir, user_dir);
  spdlog::info("serving on {} (idle_exit_ms={})", endpoint, idle_exit_ms);
  spdlog::info("RIME_SHARED_DATA_DIR: {}", shared_dir);
  spdlog::info("RIME_USER_DATA_DIR: {}", user_dir);

  using clock = std::chrono::steady_clock;
  clock::time_point idle_since = clock::now();
  bool idle_counting = true;  // 无客户端即开始计时

  while (!g_should_exit) {
    std::vector<pollfd> pfds;
    pfds.push_back({listen_fd, POLLIN, 0});
    for (auto &[key, cli] : g_clients)
      pfds.push_back({cli.fd, POLLIN, 0});

    int r = ::poll(pfds.data(), (nfds_t)pfds.size(), 100);
    if (r < 0) {
      if (errno == EINTR) continue;
      spdlog::error("poll() failed: {}", strerror(errno));
      break;
    }

    if (pfds[0].revents & POLLIN) {
      int cfd = ::accept(listen_fd, nullptr, nullptr);
      if (cfd >= 0) {
        ClientKey key = cfd;
        auto [it, inserted] = g_clients.try_emplace(key);
        it->second.fd = cfd;
        it->second.in_buf.clear();
        idle_since = clock::now();
        idle_counting = false;
        spdlog::info("client {} connected ({} active)", (long long)key,
                     (long long)g_clients.size());
        send_ready_greeting(it->second);
      }
    }

    std::vector<ClientKey> dead;
    for (size_t i = 1; i < pfds.size(); ++i) {
      short re = pfds[i].revents;
      if (!(re & (POLLIN | POLLHUP | POLLERR))) continue;
      ClientKey key = pfds[i].fd;
      auto it = g_clients.find(key);
      if (it == g_clients.end()) continue;

      if (re & (POLLHUP | POLLERR)) {
        dead.push_back(key);
        continue;
      }
      char buf[4096];
      ssize_t n = ::read(it->second.fd, buf, sizeof(buf));
      if (n <= 0) {
        if (n < 0 && errno == EINTR) continue;
        dead.push_back(key);
        continue;
      }
      idle_since = clock::now();
      idle_counting = false;
      feed_bytes(it->second, buf, static_cast<size_t>(n));
      if (it->second.dead) dead.push_back(key);
    }

    for (ClientKey key : dead) {
      auto it = g_clients.find(key);
      if (it == g_clients.end()) continue;
      spdlog::info("client {} disconnected", (long long)key);
      destroy_client_session(it->second);
      ::close(key);
      g_clients.erase(it);
    }
    if (!dead.empty()) {
      idle_since = clock::now();
      idle_counting = true;
    }

    // 空闲退出：最后一个客户端离开且超过宽限期仍未有人接入。
    if (idle_exit_ms > 0 && idle_counting && g_clients.empty()) {
      auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                         clock::now() - idle_since).count();
      if (elapsed >= idle_exit_ms) {
        spdlog::info("idle for {} ms with no clients, exiting", elapsed);
        break;
      }
    }
  }

  for (auto &[key, cli] : g_clients) {
    destroy_client_session(cli);
    ::close(cli.fd);
  }
  g_clients.clear();
  ::close(listen_fd);
  ::unlink(endpoint.c_str());

  RimeApi *api = rime_get_api();
  api->finalize();
  spdlog::info("bye");
  return 0;
}// }}}

#endif  // !_WIN32

// ---------------------------------------------------------------------------
// Serve mode: Windows TCP loopback
// ---------------------------------------------------------------------------

#ifdef _WIN32

namespace tcp_server {
static std::thread acceptor;
static std::mutex mu;
static std::vector<SOCKET> pending;
static std::atomic<bool> stop{false};
static SOCKET listener = INVALID_SOCKET;

static void close_listener() {// {{{
  if (listener != INVALID_SOCKET) {
    closesocket(listener);
    listener = INVALID_SOCKET;
  }
}// }}}

// endpoint: "[host:]port"；host 缺省 127.0.0.1，仅限数值地址（不做 DNS）。
static bool open_listener(const std::string &endpoint) {// {{{
  std::string host = "127.0.0.1";
  std::string port = endpoint;
  auto pos = endpoint.rfind(':');
  if (pos != std::string::npos) {
    host = endpoint.substr(0, pos);
    port = endpoint.substr(pos + 1);
  }
  addrinfo hints{};
  hints.ai_family   = AF_UNSPEC;      // 允许 IPv4/IPv6 loopback
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_protocol = IPPROTO_TCP;
  hints.ai_flags    = AI_NUMERICHOST | AI_NUMERICSERV | AI_PASSIVE;
  addrinfo *res = nullptr;
  if (getaddrinfo(host.c_str(), port.c_str(), &hints, &res) != 0 || !res)
    return false;

  bool ok = false;
  for (addrinfo *ai = res; ai; ai = ai->ai_next) {
    SOCKET s = ::socket(ai->ai_family, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) continue;
    // 故意不设 SO_REUSEADDR：两个 daemon 抢同一端口必须一胜一败。
    if (::bind(s, ai->ai_addr, (int)ai->ai_addrlen) == 0 &&
        ::listen(s, SOMAXCONN) == 0) {
      listener = s;
      ok = true;
      break;
    }
    closesocket(s);
  }
  freeaddrinfo(res);
  return ok;
}// }}}

static void acceptor_loop() {// {{{
  while (!stop.load()) {
    sockaddr_storage ss{};
    int len = sizeof(ss);
    SOCKET cs = ::accept(listener, reinterpret_cast<sockaddr *>(&ss), &len);
    if (cs == INVALID_SOCKET) {
      if (stop.load()) break;          // 正常关闭路径
      spdlog::warn("accept failed: {}", WSAGetLastError());
      Sleep(50);
      continue;
    }
    {
      std::lock_guard<std::mutex> lk(mu);
      pending.push_back(cs);
    }
  }
}// }}}

static void wake_acceptor() {// {{{
  stop.store(true);
  close_listener();   // 解除阻塞中的 accept()
}// }}}
}  // namespace tcp_server

static void close_client_conn(Client &c) {// {{{
  if (c.sock != INVALID_SOCKET) {
    ::shutdown(c.sock, SD_BOTH);
    closesocket(c.sock);
    c.sock = INVALID_SOCKET;
  }
}// }}}

static bool ensure_wsa() {// {{{
  WSADATA data;
  int rc = WSAStartup(MAKEWORD(2, 2), &data);
  if (rc != 0) {
    spdlog::error("WSAStartup failed: {}", rc);
    return false;
  }
  return true;
}// }}}

static bool probe_existing_daemon(const std::string &endpoint) {// {{{
  std::string host = "127.0.0.1";
  std::string port = endpoint;
  auto pos = endpoint.rfind(':');
  if (pos != std::string::npos) {
    host = endpoint.substr(0, pos);
    port = endpoint.substr(pos + 1);
  }
  addrinfo hints{};
  hints.ai_family   = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_protocol = IPPROTO_TCP;
  hints.ai_flags    = AI_NUMERICHOST | AI_NUMERICSERV;
  addrinfo *res = nullptr;
  if (getaddrinfo(host.c_str(), port.c_str(), &hints, &res) != 0 || !res)
    return false;

  bool alive = false;
  for (addrinfo *ai = res; ai && !alive; ai = ai->ai_next) {
    SOCKET s = ::socket(ai->ai_family, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) continue;
    if (::connect(s, ai->ai_addr, (int)ai->ai_addrlen) == 0) {
      std::string req = "{\"id\":1,\"type\":\"ping\"}\n";
      int sent = ::send(s, req.data(), (int)req.size(), 0);
      char buf[512];
      int got = (sent > 0)
        ? ::recv(s, buf, sizeof(buf) - 1, 0) : SOCKET_ERROR;
      if (got > 0) {
        buf[got] = '\0';
        alive = strstr(buf, "\"id\":1") != nullptr;
      }
    }
    closesocket(s);
  }
  freeaddrinfo(res);
  return alive;
}// }}}

static int run_server_windows(const std::string &tcp_endpoint,
                              long idle_exit_ms) {// {{{
  const char *shared_dir = nullptr;
  const char *user_dir   = nullptr;
  if (!read_rime_dirs(shared_dir, user_dir))
    return 1;

  if (!ensure_wsa()) return 1;

  if (!tcp_server::open_listener(tcp_endpoint)) {
    if (probe_existing_daemon(tcp_endpoint)) {
      spdlog::info("another rime-query daemon already serves on tcp {}",
                   tcp_endpoint);
      WSACleanup();
      return 0;   // 已有实例，安静退出
    }
    spdlog::error("fatal: cannot listen on tcp {} "
                  "(port taken by another program?)", tcp_endpoint);
    WSACleanup();
    return 1;
  }
  tcp_server::acceptor = std::thread(tcp_server::acceptor_loop);

  rime_init(shared_dir, user_dir);
  spdlog::info("serving on tcp {} (idle_exit_ms={})",
               tcp_endpoint, idle_exit_ms);

  long long next_id = 1;
  using clock = std::chrono::steady_clock;
  clock::time_point idle_since = clock::now();
  bool idle_counting = true;

  while (!g_should_exit) {
    {
      std::lock_guard<std::mutex> lk(tcp_server::mu);
      for (SOCKET s : tcp_server::pending) {
        ClientKey key = next_id++;
        auto [it, ok] = g_clients.try_emplace(key);
        BOOL nd = 1;
        if (setsockopt(s, IPPROTO_TCP, TCP_NODELAY,
                       (const char *)&nd, sizeof(nd)) != 0)
          spdlog::warn("TCP_NODELAY failed: {}", WSAGetLastError());
        it->second.sock = s;
        idle_since = clock::now();
        idle_counting = false;
        spdlog::info("client {} connected (tcp)", (long long)key);
        send_ready_greeting(it->second);
      }
      tcp_server::pending.clear();
    }

    std::vector<ClientKey> dead;
    for (auto &[key, cli] : g_clients) {
      char buf[4096];
      size_t got = 0;
      u_long avail = 0;
      if (ioctlsocket(cli.sock, FIONREAD, &avail) != 0) {
        dead.push_back(key);
        continue;
      }
      if (avail == 0) {
        fd_set rf;
        FD_ZERO(&rf);
        FD_SET(cli.sock, &rf);
        timeval tv{0, 0};
        int r = ::select(0, &rf, nullptr, nullptr, &tv);
        if (r > 0) {
          spdlog::info("tcp client {} reached EOF", (long long)key);
          dead.push_back(key);
        }
        continue;
      }
      int n = ::recv(cli.sock, buf, (int)sizeof(buf), 0);
      if (n <= 0) { dead.push_back(key); continue; }
      got = static_cast<size_t>(n);
      idle_since = clock::now();
      idle_counting = false;
      feed_bytes(cli, buf, got);
      if (cli.dead) dead.push_back(key);
    }

    for (ClientKey key : dead) {
      auto it = g_clients.find(key);
      if (it == g_clients.end()) continue;
      spdlog::info("client {} disconnected", (long long)key);
      destroy_client_session(it->second);
      close_client_conn(it->second);
      g_clients.erase(it);
    }
    if (!dead.empty()) {
      idle_since = clock::now();
      idle_counting = true;
    }

    if (idle_exit_ms > 0 && idle_counting && g_clients.empty()) {
      auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                         clock::now() - idle_since).count();
      if (elapsed >= idle_exit_ms) {
        spdlog::info("idle for {} ms with no clients, exiting", elapsed);
        break;
      }
    }
    Sleep(5);
  }

  for (auto &[key, cli] : g_clients) {
    destroy_client_session(cli);
    close_client_conn(cli);
  }
  g_clients.clear();

  tcp_server::wake_acceptor();
  if (tcp_server::acceptor.joinable())
    tcp_server::acceptor.join();

  RimeApi *api = rime_get_api();
  api->finalize();
  spdlog::info("bye");
  WSACleanup();
  return 0;
}// }}}

#endif  // _WIN32

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

static bool read_rime_dirs(const char *&shared_dir, const char *&user_dir) {// {{{
  shared_dir = getenv("RIME_SHARED_DATA_DIR");
  user_dir   = getenv("RIME_USER_DATA_DIR");
  if (!shared_dir || !user_dir) {
    spdlog::error("Check env $RIME_SHARED_DATA_DIR and $RIME_USER_DATA_DIR!");
    return false;
  }
  return true;
}// }}}

static void usage() {// {{{
  std::cerr <<
    "usage: rime-query [--serve|--stdio] [options]\n"
    "\n"
    "modes:\n"
    "  --serve            singleton daemon multiplexing clients over a socket\n"
    "                     (default when no mode flag is given)\n"
    "  --stdio            legacy single-client stdin/stdout mode\n"
    "\n"
    "options:\n"
#ifdef _WIN32
    "  --tcp [HOST:]PORT  tcp loopback endpoint all clients connect to\n"
    "                     (default: $RIME_QUERY_TCP, else 127.0.0.1:18666).\n"
#else
    "  --socket PATH      unix domain socket path\n"
    "                     (default: $RIME_QUERY_SOCKET, else $XDG_RUNTIME_DIR\n"
    "                      or ~/.cache + rime-query.sock)\n"
#endif
    "  --idle-exit-ms N   exit N ms after the last client leaves\n"
    "                     (default 60000, 0 = stay resident)\n"
    "  --help\n"
    "\n"
    "environment:\n"
    "  RIME_SHARED_DATA_DIR, RIME_USER_DATA_DIR, RIME_LOG"
#ifdef _WIN32
    ", RIME_QUERY_TCP"
#else
    ", RIME_QUERY_SOCKET"
#endif
    ;
}// }}}

int main(int argc, char **argv) {// {{{
  log_init();
#ifdef _WIN32
  SetConsoleCtrlHandler(console_ctrl_handler, TRUE);
#else
  std::signal(SIGINT,  on_signal);
  std::signal(SIGTERM, on_signal);
  std::signal(SIGHUP,  on_signal);
  std::signal(SIGPIPE, SIG_IGN);  // 写已断开的客户端不应杀死进程
#endif

  bool mode_stdio = false;
  bool mode_serve = false;
  std::string endpoint;       // Unix: socket 路径
  std::string tcp_endpoint;   // Windows: TCP 端点
  long idle_exit_ms = 60000;

  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg == "--serve") {
      mode_serve = true;
    } else if (arg == "--stdio") {
      mode_stdio = true;
    } else if (arg == "--socket" && i + 1 < argc) {
#ifdef _WIN32
      spdlog::warn("--socket ignored on Windows (TCP-only daemon)");
      ++i;
#else
      endpoint = argv[++i];
#endif
    } else if (arg == "--tcp") {
#ifdef _WIN32
      if (i + 1 < argc) {
        tcp_endpoint = argv[++i];
        if (tcp_endpoint == "none") {
          spdlog::error("fatal: --tcp none is not allowed "
                        "(TCP is the only transport on Windows)");
          return 1;
        }
      }
#endif
    } else if (arg == "--idle-exit-ms" && i + 1 < argc) {
      idle_exit_ms = std::atol(argv[++i]);
    } else if (arg == "--help" || arg == "-h") {
      usage();
      return 0;
    } else {
      spdlog::warn("unknown argument: {}", arg);
      usage();
      return 1;
    }
  }
  if (mode_stdio && mode_serve) {
    spdlog::error("--stdio and --serve are mutually exclusive");
    return 1;
  }

  if (mode_stdio) {
    spdlog::info("starting in stdio mode");
    const char *shared_dir = nullptr;
    const char *user_dir   = nullptr;
    if (!read_rime_dirs(shared_dir, user_dir))
      return 1;
    rime_init(shared_dir, user_dir);
    int rc = run_stdio();
    RimeApi *api = rime_get_api();
    api->finalize();
    spdlog::info("bye");
    return rc;
  }

  // 默认 serve 模式。
#ifdef _WIN32
  if (tcp_endpoint.empty()) {
    const char *env = getenv("RIME_QUERY_TCP");
    tcp_endpoint = (env && *env) ? env : "127.0.0.1:18666";
  }
  return run_server_windows(tcp_endpoint, idle_exit_ms);
#else
  if (endpoint.empty())
    endpoint = default_endpoint();
  return run_server_unix(endpoint, idle_exit_ms);
#endif
}// }}}
