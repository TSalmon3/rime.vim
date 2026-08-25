#ifdef _WIN32
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <cstdlib>
#include <csignal>
#include <cerrno>
#include <cstring>
#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <filesystem>

#ifdef _WIN32
#include <windows.h>
using ssize_t = SSIZE_T;
#else
#include <poll.h>
#include <unistd.h>
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

static RimeSessionId g_session = 0;
static volatile std::sig_atomic_t g_should_exit = 0;

static std::string g_deploy_status;

static std::vector<std::pair<std::string, bool>> g_changed_options;
static bool g_schema_changed = false;
static std::string g_schema_id;
static std::string g_schema_name;

static bool g_inline_ascii_active = false;

static void on_notification(void *, RimeSessionId, const char *message_type,
                            const char *message_value) {// {{{
    if (!message_type || !message_value)
        return;
    if (std::strcmp(message_type, "deploy") == 0) {
        g_deploy_status = message_value;
        spdlog::info("deploy notification: {}", message_value);
    } else if (std::strcmp(message_type, "option") == 0) {
        // 值形如 "ascii_mode"（开）或 "!ascii_mode"（关）。
        std::string name = message_value;
        bool on = name[0] != '!';
        if (!on) name = name.substr(1);
        g_changed_options.emplace_back(name, on);
        spdlog::info("option notification: {}={}", name, on);
    } else if (std::strcmp(message_type, "schema") == 0) {
        // 值形如 "luna_pinyin/Luna Pinyin"：<schema_id>/<schema_name>。
        std::string value = message_value;
        auto slash = value.find('/');
        g_schema_id   = value.substr(0, slash);
        g_schema_name = slash == std::string::npos ? "" : value.substr(slash + 1);
        g_schema_changed = true;
        spdlog::info("schema notification: {}", message_value);
    }
}// }}}

static void clear_key_notifications() {// {{{
    g_changed_options.clear();
    g_schema_changed = false;
}// }}}

static void fill_notifications(json &resp) {// {{{
    json opts = json::array();
    for (auto &kv : g_changed_options)
        opts.push_back({{"name", kv.first}, {"value", kv.second}});
    resp["changed_options"] = opts;
    resp["schema_changed"]  = g_schema_changed;
    if (g_schema_changed) {
        resp["schema_id"]   = g_schema_id;
        resp["schema_name"] = g_schema_name;
    }
}// }}}

#ifdef _WIN32
static BOOL WINAPI console_ctrl_handler(DWORD) {
    g_should_exit = 1;
    return TRUE;
}
#else
static void on_signal(int) {
    g_should_exit = 1;
}
#endif

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

static void rime_init(const char *shared_dir, const char *user_dir) {// {{{
    RIME_STRUCT(RimeTraits, traits);
    traits.shared_data_dir        = shared_dir;
    traits.user_data_dir          = user_dir;
    traits.app_name               = "rime.vim-query";
    traits.distribution_name      = "Rime";
    traits.distribution_code_name = "rime-query";
    traits.distribution_version   = "0.2.0";
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

static RimeSessionId get_session() {// {{{
    RimeApi *api = rime_get_api();
    if (!g_session || !api->find_session(g_session)) {
        g_session = api->create_session();
        spdlog::info("created new session: {}", (long long)g_session);
    }
    return g_session;
}// }}}

static std::string fetch_commit() {// {{{
    RimeApi *api = rime_get_api();
    RimeSessionId sid = get_session();

    RIME_STRUCT(RimeCommit, commit);
    std::string committed;
    if (sid && api->get_commit(sid, &commit)) {
        if (commit.text) committed = commit.text;
        api->free_commit(&commit);
    }
    return committed;
}// }}}

static void fill_context(json &resp) {// {{{
    RimeApi *api = rime_get_api();
    RimeSessionId sid = get_session();

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

static void finish_inline_ascii(json &resp) {// {{{
    if (!g_inline_ascii_active || resp.value("composing", true))
        return;
    g_inline_ascii_active = false;
    RimeApi *api = rime_get_api();
    RimeSessionId sid = get_session();
    if (sid) api->set_option(sid, "ascii_mode", False);
}// }}}

static json handle_request(const json &req) {// {{{
    json resp;
    resp["id"] = req.value("id", 0);

    std::string type = req.value("type", "");
    RimeApi *api = rime_get_api();

    // --- ping ---
    if (type == "ping") {
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
        RimeSessionId sid = get_session();
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

      clear_key_notifications();
      RimeSessionId sid = get_session();
      Bool accepted = api->process_key(sid, keycode, mask);

      resp["ok"]        = true;
      resp["accepted"]  = (bool)accepted;
      resp["committed"] = fetch_commit();
      fill_context(resp);
      finish_inline_ascii(resp);
      fill_notifications(resp);
      return resp;
    }

    if (type == "select") {
        int index = req.value("index", 0);
        clear_key_notifications();
        RimeSessionId sid = get_session();
        api->select_candidate_on_current_page(sid, index);

        resp["ok"]        = true;
        resp["committed"] = fetch_commit();
        fill_context(resp);
        finish_inline_ascii(resp);
        fill_notifications(resp);
        return resp;
    }

    // --- get_input ---
    if (type == "get_input") {
        RimeSessionId sid = get_session();
        const char *input = sid ? api->get_input(sid) : nullptr;

        resp["ok"]    = true;
        resp["input"] = input ? input : "";
        fill_context(resp);
        return resp;
    }

    // --- commit_composition ---
    if (type == "commit_composition") {
        clear_key_notifications();
        RimeSessionId sid = get_session();
        if (sid) api->commit_composition(sid);

        resp["ok"]        = true;
        resp["committed"] = fetch_commit();
        fill_context(resp);
        finish_inline_ascii(resp);
        fill_notifications(resp);
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

        clear_key_notifications();
        RimeSessionId sid = get_session();

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
                    committed = fetch_commit();
                } else if (style == "clear" || style == "set_ascii_mode" ||
                           style == "unset_ascii_mode") {
                    api->clear_composition(sid);
                } else if (style == "inline_ascii") {
                    g_inline_ascii_active = new_mode;
                }
            }
            api->set_option(sid, "ascii_mode", new_mode);
            // 显式切回中文时，inline 临时态随之终止，避免 finish_inline_ascii
            // 重复发一次同样的 option 通知。
            if (!new_mode)
                g_inline_ascii_active = false;
        }

        resp["ok"]           = true;
        resp["style"]        = style;
        resp["committed"]    = committed;
        resp["inline_ascii"] = g_inline_ascii_active;
        fill_context(resp);
        finish_inline_ascii(resp);
        fill_notifications(resp);
        return resp;
    }

    if (type == "reset") {
        clear_key_notifications();
        RimeSessionId sid = get_session();
        if (sid) api->clear_composition(sid);
        resp["ok"] = true;
        fill_context(resp);
        finish_inline_ascii(resp);
        fill_notifications(resp);
        return resp;
    }

    // --- deploy ---
    // 等价于 Squirrel/Weasel 的「重新部署」：强制完整重建配置、方案与用户词库。
    if (type == "deploy") {
        if (g_session) {
            api->destroy_session(g_session);
            g_session = 0;
        }
        g_inline_ascii_active = false;
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
        clear_key_notifications();
        RimeSessionId sid = get_session();
        if (!sid) {
            resp["ok"]    = false;
            resp["error"] = "no active session";
            return resp;
        }
        Bool current   = api->get_option(sid, option.c_str());
        Bool new_value = current ? False : True;
        api->set_option(sid, option.c_str(), new_value);

        if (option == "ascii_mode" && !new_value)
            g_inline_ascii_active = false;

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
        clear_key_notifications();
        RimeSessionId sid = get_session();
        if (!sid) {
            resp["ok"]    = false;
            resp["error"] = "no active session";
            return resp;
        }
        Bool value = req.value("value", false) ? True : False;
        api->set_option(sid, option.c_str(), value);

        if (option == "ascii_mode" && !value)
            g_inline_ascii_active = false;

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
        RimeSessionId sid = get_session();
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

// 处理单行请求并写出响应；解析失败也回一个错误包，保持原有行为。
static void handle_line(const std::string &line) {// {{{
    try {
        json req  = json::parse(line);
        spdlog::debug(">> {}", line);
        json resp = handle_request(req);
        std::cout << resp.dump() << "\n";
        spdlog::debug("<< {}", resp.dump());
        std::cout.flush();
    } catch (const json::exception &e) {
        json err;
        err["id"]    = 0;
        err["ok"]    = false;
        err["error"] = std::string("JSON parse error: ") + e.what();
        std::cout << err.dump() << "\n";
        std::cout.flush();
    }
}// }}}

int main() {// {{{
    log_init();
#ifdef _WIN32
    SetConsoleCtrlHandler(console_ctrl_handler, TRUE);
#else
    std::signal(SIGINT,  on_signal);
    std::signal(SIGTERM, on_signal);
    std::signal(SIGHUP,  on_signal);
#endif

    const char *shared_dir = getenv("RIME_SHARED_DATA_DIR");
    const char *user_dir   = getenv("RIME_USER_DATA_DIR");

    if (!shared_dir || !user_dir) {
      spdlog::info("Check env $RIME_SHARED_DATA_DIR and $RIME_USER_DATA_DIR!!!");
      return 1;
    }

    rime_init(shared_dir, user_dir);

    spdlog::info("RIME_LOG: {}", getenv("RIME_LOG") ? getenv("RIME_LOG") : "(none)");
    spdlog::info("RIME_SHARED_DATA_DIR: {}", shared_dir);
    spdlog::info("RIME_USER_DATA_DIR: {}", user_dir);

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
            handle_line(line);
        }
    }

    RimeApi *api = rime_get_api();
    if (g_session) api->destroy_session(g_session);
    api->finalize();

    spdlog::info("bye");
    return 0;
}// }}}
