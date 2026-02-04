#pragma once
#include "stdafx.h"
#define gml_ext_h
#include <vector>
#if ((defined(_MSVC_LANG) && _MSVC_LANG >= 201703L) || __cplusplus >= 201703L)
#include <optional>
#endif
#include <stdint.h>
#include <cstring>
#include <tuple>
using namespace std;

#define dllg /* tag */
#define dllgm /* tag;mangled */

#if defined(_WINDOWS)
#define dllx extern "C" __declspec(dllexport)
#define dllm __declspec(dllexport)
#elif defined(GNUC)
#define dllx extern "C" __attribute__ ((visibility("default"))) 
#define dllm __attribute__ ((visibility("default"))) 
#else
#define dllx extern "C"
#define dllm /* */
#endif

#ifdef _WINDEF_
/// auto-generates a window_handle() on GML side
typedef HWND GAME_HWND;
#endif

/// auto-generates an asset_get_index("argument_name") on GML side
typedef int gml_asset_index_of;
/// Wraps a C++ pointer for GML.
template <typename T> using gml_ptr = T*;
/// Same as gml_ptr, but replaces the GML-side pointer by a nullptr after passing it to C++
template <typename T> using gml_ptr_destroy = T*;
/// Wraps any ID (or anything that casts to int64, really) for GML.
template <typename T> using gml_id = T;
/// Same as gml_id, but replaces the GML-side ID by a 0 after passing it to C++
template <typename T> using gml_id_destroy = T;

class gml_buffer {
private:
	uint8_t* _data;
	int32_t _size;
	int32_t _tell;
public:
	gml_buffer() : _data(nullptr), _tell(0), _size(0) {}
	gml_buffer(uint8_t* data, int32_t size, int32_t tell) : _data(data), _size(size), _tell(tell) {}

	inline uint8_t* data() { return _data; }
	inline int32_t tell() { return _tell; }
	inline int32_t size() { return _size; }
};

class gml_istream {
	uint8_t* pos;
	uint8_t* start;
public:
	gml_istream(void* origin) : pos((uint8_t*)origin), start((uint8_t*)origin) {}

	template<class T> T read() {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be read");
		T result{};
		std::memcpy(&result, pos, sizeof(T));
		pos += sizeof(T);
		return result;
	}

	char* read_string() {
		char* r = (char*)pos;
		while (*pos != 0) pos++;
		pos++;
		return r;
	}

	template<class T> std::vector<T> read_vector() {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be read");
		auto n = read<uint32_t>();
		std::vector<T> vec(n);
		std::memcpy(vec.data(), pos, sizeof(T) * n);
		pos += sizeof(T) * n;
		return vec;
	}
	#ifdef tiny_array_h
	template<class T> tiny_const_array<T> read_tiny_const_array() {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be read");
		auto n = read<uint32_t>();
		tiny_const_array<T> arr((T*)pos, sizeof(T));
		pos += sizeof(T) * n;
		return arr;
	}
	#endif
	
	std::vector<const char*> read_string_vector() {
		auto n = read<uint32_t>();
		std::vector<const char*> vec(n);
		for (auto i = 0u; i < n; i++) {
			vec[i] = read_string();
		}
		return vec;
	}

	gml_buffer read_gml_buffer() {
		auto _data = (uint8_t*)read<int64_t>();
		auto _size = read<int32_t>();
		auto _tell = read<int32_t>();
		return gml_buffer(_data, _size, _tell);
	}

	#ifdef tiny_optional_h
	template<class T> tiny_optional<T> read_tiny_optional() {
		if (read<bool>()) {
			return read<T>;
		} else return {};
	}
	#endif

	#pragma region Tuples
	#if ((defined(_MSVC_LANG) && _MSVC_LANG >= 201703L) || __cplusplus >= 201703L)
	template<typename... Args>
	std::tuple<Args...> read_tuple() {
		std::tuple<Args...> tup;
		std::apply([this](auto&&... arg) {
			((
				arg = this->read<std::remove_reference_t<decltype(arg)>>()
				), ...);
			}, tup);
		return tup;
	}

	template<class T> optional<T> read_optional() {
		if (read<bool>()) {
			return read<T>;
		} else return {};
	}
	#else
	template<class A, class B> std::tuple<A, B> read_tuple() {
		A a = read<A>();
		B b = read<B>();
		return std::tuple<A, B>(a, b);
	}

	template<class A, class B, class C> std::tuple<A, B, C> read_tuple() {
		A a = read<A>();
		B b = read<B>();
		C c = read<C>();
		return std::tuple<A, B, C>(a, b, c);
	}

	template<class A, class B, class C, class D> std::tuple<A, B, C, D> read_tuple() {
		A a = read<A>();
		B b = read<B>();
		C c = read<C>();
		D d = read<d>();
		return std::tuple<A, B, C, D>(a, b, c, d);
	}
	#endif
};

class gml_ostream {
	uint8_t* pos;
	uint8_t* start;
public:
	gml_ostream(void* origin) : pos((uint8_t*)origin), start((uint8_t*)origin) {}

	template<class T> void write(T val) {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be write");
		memcpy(pos, &val, sizeof(T));
		pos += sizeof(T);
	}

	void write_string(const char* s) {
		for (int i = 0; s[i] != 0; i++) write<char>(s[i]);
		write<char>(0);
	}

	template<class T> void write_vector(std::vector<T>& vec) {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be write");
		auto n = vec.size();
		write<uint32_t>((uint32_t)n);
		memcpy(pos, vec.data(), n * sizeof(T));
		pos += n * sizeof(T);
	}

	#ifdef tiny_array_h
	template<class T> void write_tiny_array(tiny_array<T>& arr) {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be write");
		auto n = arr.size();
		write<uint32_t>(n);
		memcpy(pos, arr.data(), n * sizeof(T));
		pos += n * sizeof(T);
	}
	template<class T> void write_tiny_const_array(tiny_const_array<T>& arr) {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be write");
		auto n = arr.size();
		write<uint32_t>(n);
		memcpy(pos, arr.data(), n * sizeof(T));
		pos += n * sizeof(T);
	}
	#endif
	
	void write_string_vector(std::vector<const char*> vec) {
		auto n = vec.size();
		write<uint32_t>((uint32_t)n);
		for (auto i = 0u; i < n; i++) {
			write_string(vec[i]);
		}
	}

	#ifdef tiny_optional_h
	template<typename T> void write_tiny_optional(tiny_optional<T>& val) {
		auto hasValue = val.has_value();
		write<bool>(hasValue);
		if (hasValue) write<T>(val.value());
	}
	#endif

	#if ((defined(_MSVC_LANG) && _MSVC_LANG >= 201703L) || __cplusplus >= 201703L)
	template<typename... Args>
	void write_tuple(std::tuple<Args...> tup) {
		std::apply([this](auto&&... arg) {
			(this->write(arg), ...);
			}, tup);
	}

	template<class T> void write_optional(optional<T>& val) {
		auto hasValue = val.has_value();
		write<bool>(hasValue);
		if (hasValue) write<T>(val.value());
	}
	#else
	template<class A, class B> void write_tuple(std::tuple<A, B>& tup) {
		write<A>(std::get<0>(tup));
		write<B>(std::get<1>(tup));
	}
	template<class A, class B, class C> void write_tuple(std::tuple<A, B, C>& tup) {
		write<A>(std::get<0>(tup));
		write<B>(std::get<1>(tup));
		write<C>(std::get<2>(tup));
	}
	template<class A, class B, class C, class D> void write_tuple(std::tuple<A, B, C, D>& tup) {
		write<A>(std::get<0>(tup));
		write<B>(std::get<1>(tup));
		write<C>(std::get<2>(tup));
		write<D>(std::get<3>(tup));
	}
	#endif
};
//{{NO_DEPENDENCIES}}
// Microsoft Visual C++ generated include file.
// Used by winwin.rc

// Next default values for new objects
// 
#ifdef APSTUDIO_INVOKED
#ifndef APSTUDIO_READONLY_SYMBOLS
#define _APS_NEXT_RESOURCE_VALUE        101
#define _APS_NEXT_COMMAND_VALUE         40001
#define _APS_NEXT_CONTROL_VALUE         1001
#define _APS_NEXT_SYMED_VALUE           101
#endif
#endif
// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#ifdef _WINDOWS
	#include "targetver.h"
	
	#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
	#include <windows.h>
	#include <d3d11.h>
#endif

#if defined(WIN32)
#define dllx extern "C" __declspec(dllexport)
#elif defined(GNUC)
#define dllx extern "C" __attribute__ ((visibility("default"))) 
#else
#define dllx extern "C"
#endif

#define trace(...) { printf("[" __FUNCTION__ "] "); printf(__VA_ARGS__); printf("\n"); fflush(stdout); }

template<typename T> T* malloc_arr(size_t count) {
	return (T*)malloc(sizeof(T) * count);
}
template<typename T> T* realloc_arr(T* arr, size_t count) {
	return (T*)realloc(arr, sizeof(T) * count);
}
template<typename T> T* memcpy_arr(T* dst, const T* src, size_t count) {
	return (T*)memcpy(dst, src, sizeof(T) * count);
}

#include "gml_ext.h"

// TODO: reference additional headers your program requires here#pragma once
#include "stdafx.h"

class StringConv {
public:
    char* cbuf = NULL;
    size_t cbuf_size = 0;
    WCHAR* wbuf = NULL;
    size_t wbuf_size = 0;
    StringConv() {

    }
    void init() {
        cbuf = nullptr;
        cbuf_size = 0;
        wbuf = nullptr;
        wbuf_size = 0;
    }
    LPWSTR wget(size_t size) {
        if (wbuf_size < size) {
            if (wbuf != nullptr) {
                wbuf = realloc_arr(wbuf, size);
            } else wbuf = malloc_arr<wchar_t>(size);
            wbuf_size = size;
        }
        return wbuf;
    }
    LPCWSTR proc(const char* src, int cp = CP_UTF8) {
        auto size = MultiByteToWideChar(cp, 0, src, -1, NULL, 0);
        LPWSTR buf = wget((size_t)size);
        MultiByteToWideChar(cp, 0, src, -1, wbuf, size);
        return wbuf;
    }
    char* get(size_t size) {
        if (cbuf_size < size) {
            if (cbuf != nullptr) {
                cbuf = realloc_arr(cbuf, size);
            } else cbuf = malloc_arr<char>(size);
            cbuf_size = size;
        }
        return cbuf;
    }
    char* proc(LPCWSTR src, int cp = CP_UTF8) {
        auto size = WideCharToMultiByte(cp, 0, src, -1, NULL, 0, NULL, NULL);
        char* buf = get((size_t)size);
        WideCharToMultiByte(cp, 0, src, -1, buf, size, NULL, NULL);
        return buf;
    }
};
extern StringConv ww_c1, ww_c2;
#pragma once

// Including SDKDDKVer.h defines the highest available Windows platform.

// If you wish to build your application for a previous Windows platform, include WinSDKVer.h and
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.

#include <SDKDDKVer.h>
#pragma once
#include "stdafx.h"
#include <vector>
#include <unordered_map>
#include "StringConv.h"

struct winwin;
struct wm_base_t {
    ID3D11Device* device;
    ID3D11DeviceContext* context;
    HWND main_hwnd;
    IDXGISwapChain* main_swapchain;
    HINSTANCE hInstance;
    winwin* ref;
};
extern wm_base_t ww_base;

///
enum class winwin_kind {
    normal,
    borderless,
    tool,
};

struct ww_keybits {
    uint32_t segments[8]{};
    void clear() {
        memset(segments, 0, sizeof(segments));
    }
    void assign(ww_keybits& other) {
        memcpy(segments, other.segments, sizeof(segments));
    }
    bool getAny() {
        for (auto i = 0u; i < std::size(segments); i++) {
            if (segments[i] != 0) return true;
        }
        return false;
    }
    bool get(int i) {
        if (i < 0 || i >= 256) return false;
        if (i == 0) return !getAny();
        if (i == 1) return getAny();
        return ((segments[i >> 5] >> (i & 31)) & 1) != 0;
    }
    bool set(int i, bool val) {
        if (i < 0 || i >= 256) return false;
        if (val) {
            segments[i >> 5] |= 1 << (i & 31);
        } else {
            segments[i >> 5] &= ~(1 << (i & 31));
        }
        return true;
    }
};
struct ww_keybits_tri {
    ww_keybits down{};
    ww_keybits pressed{};
    ww_keybits released{};
};
struct ww_keyboard_string {
    int size = 0;
    int capacity = 0;
    uint32_t* data = nullptr;
    ww_keyboard_string() {
        capacity = 128;
        data = malloc_arr<uint32_t>(capacity);
    }
    ~ww_keyboard_string() {
        free(data);
    }
};

struct ww_mousebits {
    uint8_t bits = 0;
    void clear() {
        bits = 0;
    }
    void assign(ww_mousebits& other) {
        bits = other.bits;
    }
    bool get(int i) {
        if (i < 0 || i >= 8) return false;
        return (bits & (1 << i)) != 0;
    }
    bool set(int i, bool val) {
        if (i < 0 || i >= 8) return false;
        if (val) {
            bits |= (1 << i);
        } else {
            bits &= ~(1 << i);
        }
        return true;
    }
};
struct ww_mousebits_tri {
    ww_mousebits down{}, pressed{}, released{};
    int wheel = 0, hwheel = 0;
};
struct ww_size {
    std::optional<int> width = {}, height = {};
};

struct winwin_config;
struct winwin {
    HWND hwnd = NULL;
    IDXGISwapChain* swapchain = nullptr;
    ID3D11RenderTargetView* rtv = nullptr;
    //
    winwin_kind kind = winwin_kind::normal;
    bool has_shadow = true;
    //
    struct {
        int width, height;
        int new_width, new_height;
        int resize_in = 0;
    } buf;
    //
    ww_keybits_tri keys{}, keys_next{};
    ww_keyboard_string keyboard_string{};
    //
    HCURSOR cursor = NULL;
    int mouse_x = 0, mouse_y = 0;
    ww_mousebits_tri mouse{}, mouse_next{};
    int8_t mouse_buttons_held = 0;
    bool mouse_tracking = false;
    bool mouse_over = false;
    //
    ww_size minSize{}, maxSize{};
    //
    int8_t sync_interval = 0;
    int8_t close_button = 0;
    // threading
    struct {
        winwin_config* config = nullptr;
        struct { int x, y, width, height; } rect;
        bool ok = false;
    } init;
    struct {
        HANDLE thread = NULL;
        DWORD thread_id = 0;
        CRITICAL_SECTION* section = nullptr;
        HANDLE ready = NULL;
        void enter() {
            if (section) EnterCriticalSection(section);
        }
        void leave() {
            if (section) LeaveCriticalSection(section);
        }
    } mt;
    //
    ~winwin();
};
using ww_ptr = gml_ptr<winwin>;

extern std::vector<winwin*> ww_list;
extern std::unordered_map<HWND, winwin*> ww_map;
inline winwin* ww_find(HWND hwnd) {
    if (hwnd == NULL) return nullptr;
    auto pair = ww_map.find(hwnd);
    return pair != ww_map.end() ? pair->second : nullptr;
}
extern ww_ptr ww_main;
extern ww_ptr ww_target;

constexpr DXGI_FORMAT ww_dxgi_format = DXGI_FORMAT_R8G8B8A8_UNORM;
constexpr LONG WW_WS_EX_CLICKTHROUGH = (WS_EX_TRANSPARENT | WS_EX_LAYERED);

#define ww_cc(str) ww_c1.proc(str)
inline LONG rect_width(RECT& r) { return r.right - r.left; }
inline LONG rect_height(RECT& r) { return r.bottom - r.top; }

using ww_ptr_create = ww_ptr;
using ww_ptr_find = ww_ptr;
using ww_ptr_destroy = gml_ptr_destroy<winwin>;
#pragma once

/**
    @dllg:type ww_ptr_create
    @gmlRead
    var _ptr = buffer_read(_buf, buffer_u64);
    var _box;
    if (_ptr != 0) {
        _ptr = ptr(_ptr);
        _box = new winwin(_ptr);
        winwin_map[?_ptr] = _box;
        ds_list_add(winwin_list, _box);
    } else _box = undefined;
    return _box;
**/
/**
    @dllg:type ww_ptr_find
    @gmlRead
    var _ptr = buffer_read(_buf, buffer_u64);
    var _box;
    if (_ptr != 0) {
        _ptr = ptr(_ptr);
        _box = global.__winwin_map[?_ptr];
        if (_box == undefined) {
            _box = new winwin(_ptr);
            winwin_map[?_ptr] = _box;
            ds_list_add(winwin_list, _box);
        }
    } else _box = undefined;
    return _box;
**/
/**
    @dllg:type ww_ptr_destroy
    @gmlWrite
    var _box_0 = $value;
    if (instanceof(_box_0) != "winwin") { show_error("Expected a winwin, got " + string(_box_0), true); exit }
    var _ptr_0 = _box_0.__ptr__;
    if (_ptr_0 == pointer_null) { show_error("This winwin is already destroyed.", true); exit; }
    _box_0.__ptr__ = pointer_null;
    ds_map_delete(winwin_map, _ptr_0);
    var _ind = ds_list_find_index(winwin_list, _box_0);
    if (_ind >= 0) ds_list_delete(winwin_list, _ind);
    buffer_write(_buf, buffer_u64, int64(_ptr_0));
**/#pragma once
#include "winwin.h"

struct winwin_config {
    const char* caption;
    winwin_kind kind;
    bool resize;
    bool show;
    bool topmost;
    bool taskbar_button;
    bool clickthrough;
    bool noactivate;
    bool per_pixel_alpha;
    bool thread;
    int8_t vsync;
    int8_t close_button;
    std::optional<ww_ptr> owner;
};#pragma once
#include <Windows.h>

const char* WM_NAME(UINT msg) {
	switch (msg) {
		case 0x0000: return "WM_NULL";
		case 0x0001: return "WM_CREATE";
		case 0x0002: return "WM_DESTROY";
		case 0x0003: return "WM_MOVE";
		case 0x0005: return "WM_SIZE";
		case 0x0006: return "WM_ACTIVATE";
		case 0x0007: return "WM_SETFOCUS";
		case 0x0008: return "WM_KILLFOCUS";
		case 0x000A: return "WM_ENABLE";
		case 0x000B: return "WM_SETREDRAW";
		case 0x000C: return "WM_SETTEXT";
		case 0x000D: return "WM_GETTEXT";
		case 0x000E: return "WM_GETTEXTLENGTH";
		case 0x000F: return "WM_PAINT";
		case 0x0010: return "WM_CLOSE";
		case 0x0011: return "WM_QUERYENDSESSION";
		case 0x0013: return "WM_QUERYOPEN";
		case 0x0016: return "WM_ENDSESSION";
		case 0x0012: return "WM_QUIT";
		case 0x0014: return "WM_ERASEBKGND";
		case 0x0015: return "WM_SYSCOLORCHANGE";
		case 0x0018: return "WM_SHOWWINDOW";
		case 0x001A: return "WM_WININICHANGE";
		case 0x001B: return "WM_DEVMODECHANGE";
		case 0x001C: return "WM_ACTIVATEAPP";
		case 0x001D: return "WM_FONTCHANGE";
		case 0x001E: return "WM_TIMECHANGE";
		case 0x001F: return "WM_CANCELMODE";
		case 0x0020: return "WM_SETCURSOR";
		case 0x0021: return "WM_MOUSEACTIVATE";
		case 0x0022: return "WM_CHILDACTIVATE";
		case 0x0023: return "WM_QUEUESYNC";
		case 0x0024: return "WM_GETMINMAXINFO";
		case 0x0026: return "WM_PAINTICON";
		case 0x0027: return "WM_ICONERASEBKGND";
		case 0x0028: return "WM_NEXTDLGCTL";
		case 0x002A: return "WM_SPOOLERSTATUS";
		case 0x002B: return "WM_DRAWITEM";
		case 0x002C: return "WM_MEASUREITEM";
		case 0x002D: return "WM_DELETEITEM";
		case 0x002E: return "WM_VKEYTOITEM";
		case 0x002F: return "WM_CHARTOITEM";
		case 0x0030: return "WM_SETFONT";
		case 0x0031: return "WM_GETFONT";
		case 0x0032: return "WM_SETHOTKEY";
		case 0x0033: return "WM_GETHOTKEY";
		case 0x0037: return "WM_QUERYDRAGICON";
		case 0x0039: return "WM_COMPAREITEM";
		case 0x003D: return "WM_GETOBJECT";
		case 0x0041: return "WM_COMPACTING";
		case 0x0044: return "WM_COMMNOTIFY";
		case 0x0046: return "WM_WINDOWPOSCHANGING";
		case 0x0047: return "WM_WINDOWPOSCHANGED";
		case 0x0048: return "WM_POWER";
		case 0x004A: return "WM_COPYDATA";
		case 0x004B: return "WM_CANCELJOURNAL";
		case 0x004E: return "WM_NOTIFY";
		case 0x0050: return "WM_INPUTLANGCHANGEREQUEST";
		case 0x0051: return "WM_INPUTLANGCHANGE";
		case 0x0052: return "WM_TCARD";
		case 0x0053: return "WM_HELP";
		case 0x0054: return "WM_USERCHANGED";
		case 0x0055: return "WM_NOTIFYFORMAT";
		case 0x007B: return "WM_CONTEXTMENU";
		case 0x007C: return "WM_STYLECHANGING";
		case 0x007D: return "WM_STYLECHANGED";
		case 0x007E: return "WM_DISPLAYCHANGE";
		case 0x007F: return "WM_GETICON";
		case 0x0080: return "WM_SETICON";
		case 0x0081: return "WM_NCCREATE";
		case 0x0082: return "WM_NCDESTROY";
		case 0x0083: return "WM_NCCALCSIZE";
		case 0x0084: return "WM_NCHITTEST";
		case 0x0085: return "WM_NCPAINT";
		case 0x0086: return "WM_NCACTIVATE";
		case 0x0087: return "WM_GETDLGCODE";
		case 0x0088: return "WM_SYNCPAINT";
		case 0x00A0: return "WM_NCMOUSEMOVE";
		case 0x00A1: return "WM_NCLBUTTONDOWN";
		case 0x00A2: return "WM_NCLBUTTONUP";
		case 0x00A3: return "WM_NCLBUTTONDBLCLK";
		case 0x00A4: return "WM_NCRBUTTONDOWN";
		case 0x00A5: return "WM_NCRBUTTONUP";
		case 0x00A6: return "WM_NCRBUTTONDBLCLK";
		case 0x00A7: return "WM_NCMBUTTONDOWN";
		case 0x00A8: return "WM_NCMBUTTONUP";
		case 0x00A9: return "WM_NCMBUTTONDBLCLK";
		case 0x00AB: return "WM_NCXBUTTONDOWN";
		case 0x00AC: return "WM_NCXBUTTONUP";
		case 0x00AD: return "WM_NCXBUTTONDBLCLK";
		case 0x00FE: return "WM_INPUT_DEVICE_CHANGE";
		case 0x00FF: return "WM_INPUT";
		case 0x0100: return "WM_KEYDOWN";
		case 0x0101: return "WM_KEYUP";
		case 0x0102: return "WM_CHAR";
		case 0x0103: return "WM_DEADCHAR";
		case 0x0104: return "WM_SYSKEYDOWN";
		case 0x0105: return "WM_SYSKEYUP";
		case 0x0106: return "WM_SYSCHAR";
		case 0x0107: return "WM_SYSDEADCHAR";
		case 0x0109: return "WM_UNICHAR";
		case 0x0108: return "WM_KEYLAST";
		case 0x010D: return "WM_IME_STARTCOMPOSITION";
		case 0x010E: return "WM_IME_ENDCOMPOSITION";
		case 0x010F: return "WM_IME_COMPOSITION";
		case 0x0110: return "WM_INITDIALOG";
		case 0x0111: return "WM_COMMAND";
		case 0x0112: return "WM_SYSCOMMAND";
		case 0x0113: return "WM_TIMER";
		case 0x0114: return "WM_HSCROLL";
		case 0x0115: return "WM_VSCROLL";
		case 0x0116: return "WM_INITMENU";
		case 0x0117: return "WM_INITMENUPOPUP";
		case 0x0119: return "WM_GESTURE";
		case 0x011A: return "WM_GESTURENOTIFY";
		case 0x011F: return "WM_MENUSELECT";
		case 0x0120: return "WM_MENUCHAR";
		case 0x0121: return "WM_ENTERIDLE";
		case 0x0122: return "WM_MENURBUTTONUP";
		case 0x0123: return "WM_MENUDRAG";
		case 0x0124: return "WM_MENUGETOBJECT";
		case 0x0125: return "WM_UNINITMENUPOPUP";
		case 0x0126: return "WM_MENUCOMMAND";
		case 0x0127: return "WM_CHANGEUISTATE";
		case 0x0128: return "WM_UPDATEUISTATE";
		case 0x0129: return "WM_QUERYUISTATE";
		case 0x0132: return "WM_CTLCOLORMSGBOX";
		case 0x0133: return "WM_CTLCOLOREDIT";
		case 0x0134: return "WM_CTLCOLORLISTBOX";
		case 0x0135: return "WM_CTLCOLORBTN";
		case 0x0136: return "WM_CTLCOLORDLG";
		case 0x0137: return "WM_CTLCOLORSCROLLBAR";
		case 0x0138: return "WM_CTLCOLORSTATIC";
		case 0x0200: return "WM_MOUSEMOVE";
		case 0x0201: return "WM_LBUTTONDOWN";
		case 0x0202: return "WM_LBUTTONUP";
		case 0x0203: return "WM_LBUTTONDBLCLK";
		case 0x0204: return "WM_RBUTTONDOWN";
		case 0x0205: return "WM_RBUTTONUP";
		case 0x0206: return "WM_RBUTTONDBLCLK";
		case 0x0207: return "WM_MBUTTONDOWN";
		case 0x0208: return "WM_MBUTTONUP";
		case 0x0209: return "WM_MBUTTONDBLCLK";
		case 0x020A: return "WM_MOUSEWHEEL";
		case 0x020B: return "WM_XBUTTONDOWN";
		case 0x020C: return "WM_XBUTTONUP";
		case 0x020D: return "WM_XBUTTONDBLCLK";
		case 0x020E: return "WM_MOUSEHWHEEL";
		case 0x0210: return "WM_PARENTNOTIFY";
		case 0x0211: return "WM_ENTERMENULOOP";
		case 0x0212: return "WM_EXITMENULOOP";
		case 0x0213: return "WM_NEXTMENU";
		case 0x0214: return "WM_SIZING";
		case 0x0215: return "WM_CAPTURECHANGED";
		case 0x0216: return "WM_MOVING";
		case 0x0218: return "WM_POWERBROADCAST";
		case 0x0219: return "WM_DEVICECHANGE";
		case 0x0220: return "WM_MDICREATE";
		case 0x0221: return "WM_MDIDESTROY";
		case 0x0222: return "WM_MDIACTIVATE";
		case 0x0223: return "WM_MDIRESTORE";
		case 0x0224: return "WM_MDINEXT";
		case 0x0225: return "WM_MDIMAXIMIZE";
		case 0x0226: return "WM_MDITILE";
		case 0x0227: return "WM_MDICASCADE";
		case 0x0228: return "WM_MDIICONARRANGE";
		case 0x0229: return "WM_MDIGETACTIVE";
		case 0x0230: return "WM_MDISETMENU";
		case 0x0231: return "WM_ENTERSIZEMOVE";
		case 0x0232: return "WM_EXITSIZEMOVE";
		case 0x0233: return "WM_DROPFILES";
		case 0x0234: return "WM_MDIREFRESHMENU";
		case 0x238: return "WM_POINTERDEVICECHANGE";
		case 0x239: return "WM_POINTERDEVICEINRANGE";
		case 0x23A: return "WM_POINTERDEVICEOUTOFRANGE";
		case 0x0240: return "WM_TOUCH";
		case 0x0241: return "WM_NCPOINTERUPDATE";
		case 0x0242: return "WM_NCPOINTERDOWN";
		case 0x0243: return "WM_NCPOINTERUP";
		case 0x0245: return "WM_POINTERUPDATE";
		case 0x0246: return "WM_POINTERDOWN";
		case 0x0247: return "WM_POINTERUP";
		case 0x0249: return "WM_POINTERENTER";
		case 0x024A: return "WM_POINTERLEAVE";
		case 0x024B: return "WM_POINTERACTIVATE";
		case 0x024C: return "WM_POINTERCAPTURECHANGED";
		case 0x024D: return "WM_TOUCHHITTESTING";
		case 0x024E: return "WM_POINTERWHEEL";
		case 0x024F: return "WM_POINTERHWHEEL";
		case 0x0251: return "WM_POINTERROUTEDTO";
		case 0x0252: return "WM_POINTERROUTEDAWAY";
		case 0x0253: return "WM_POINTERROUTEDRELEASED";
		case 0x0281: return "WM_IME_SETCONTEXT";
		case 0x0282: return "WM_IME_NOTIFY";
		case 0x0283: return "WM_IME_CONTROL";
		case 0x0284: return "WM_IME_COMPOSITIONFULL";
		case 0x0285: return "WM_IME_SELECT";
		case 0x0286: return "WM_IME_CHAR";
		case 0x0288: return "WM_IME_REQUEST";
		case 0x0290: return "WM_IME_KEYDOWN";
		case 0x0291: return "WM_IME_KEYUP";
		case 0x02A1: return "WM_MOUSEHOVER";
		case 0x02A3: return "WM_MOUSELEAVE";
		case 0x02A0: return "WM_NCMOUSEHOVER";
		case 0x02A2: return "WM_NCMOUSELEAVE";
		case 0x02B1: return "WM_WTSSESSION_CHANGE";
		case 0x02c0: return "WM_TABLET_FIRST";
		case 0x02df: return "WM_TABLET_LAST";
		case 0x02E0: return "WM_DPICHANGED";
		case 0x02E2: return "WM_DPICHANGED_BEFOREPARENT";
		case 0x02E3: return "WM_DPICHANGED_AFTERPARENT";
		case 0x02E4: return "WM_GETDPISCALEDSIZE";
		case 0x0300: return "WM_CUT";
		case 0x0301: return "WM_COPY";
		case 0x0302: return "WM_PASTE";
		case 0x0303: return "WM_CLEAR";
		case 0x0304: return "WM_UNDO";
		case 0x0305: return "WM_RENDERFORMAT";
		case 0x0306: return "WM_RENDERALLFORMATS";
		case 0x0307: return "WM_DESTROYCLIPBOARD";
		case 0x0308: return "WM_DRAWCLIPBOARD";
		case 0x0309: return "WM_PAINTCLIPBOARD";
		case 0x030A: return "WM_VSCROLLCLIPBOARD";
		case 0x030B: return "WM_SIZECLIPBOARD";
		case 0x030C: return "WM_ASKCBFORMATNAME";
		case 0x030D: return "WM_CHANGECBCHAIN";
		case 0x030E: return "WM_HSCROLLCLIPBOARD";
		case 0x030F: return "WM_QUERYNEWPALETTE";
		case 0x0310: return "WM_PALETTEISCHANGING";
		case 0x0311: return "WM_PALETTECHANGED";
		case 0x0312: return "WM_HOTKEY";
		case 0x0317: return "WM_PRINT";
		case 0x0318: return "WM_PRINTCLIENT";
		case 0x0319: return "WM_APPCOMMAND";
		case 0x031A: return "WM_THEMECHANGED";
		case 0x031D: return "WM_CLIPBOARDUPDATE";
		case 0x031E: return "WM_DWMCOMPOSITIONCHANGED";
		case 0x031F: return "WM_DWMNCRENDERINGCHANGED";
		case 0x0320: return "WM_DWMCOLORIZATIONCOLORCHANGED";
		case 0x0321: return "WM_DWMWINDOWMAXIMIZEDCHANGE";
		case 0x0323: return "WM_DWMSENDICONICTHUMBNAIL";
		case 0x0326: return "WM_DWMSENDICONICLIVEPREVIEWBITMAP";
		case 0x033F: return "WM_GETTITLEBARINFOEX";
		case 0x0358: return "WM_HANDHELDFIRST";
		case 0x035F: return "WM_HANDHELDLAST";
		case 0x0360: return "WM_AFXFIRST";
		case 0x037F: return "WM_AFXLAST";
		case 0x0380: return "WM_PENWINFIRST";
		case 0x038F: return "WM_PENWINLAST";
		case 0x8000: return "WM_APP";
		case 0x0400: return "WM_USER";
	}
	return nullptr;
}#include "gml_ext.h"
#include "winwin.h"
#include "winwin_config.h"
extern ww_ptr_create winwin_init_2();
dllx double winwin_init_2_raw(void* _inout_ptr, double _inout_ptr_size) {
	gml_istream _in(_inout_ptr);
	ww_ptr_create _result = winwin_init_2();
	gml_ostream _out(_inout_ptr);
	_out.write<ww_ptr_create>(_result);
	return 1;
}

extern ww_ptr_create winwin_create(int x, int y, int width, int height, winwin_config config);
dllx double winwin_create_raw(void* _inout_ptr, double _inout_ptr_size, double _arg_x, double _arg_y) {
	gml_istream _in(_inout_ptr);
	int _arg_width = _in.read<int>();
	int _arg_height = _in.read<int>();
	winwin_config _a_config;
	_a_config.caption = _in.read_string();
	_a_config.kind = (winwin_kind)_in.read<int>();
	_a_config.resize = _in.read<bool>();
	_a_config.show = _in.read<bool>();
	_a_config.topmost = _in.read<bool>();
	_a_config.taskbar_button = _in.read<bool>();
	_a_config.clickthrough = _in.read<bool>();
	_a_config.noactivate = _in.read<bool>();
	_a_config.per_pixel_alpha = _in.read<bool>();
	_a_config.thread = _in.read<bool>();
	_a_config.vsync = _in.read<int8_t>();
	_a_config.close_button = _in.read<int8_t>();
	std::optional<ww_ptr> _a_config_f_owner;
	if (_in.read<bool>()) {
		_a_config_f_owner = (ww_ptr)_in.read<int64_t>();
	} else _a_config_f_owner = {};
	_a_config.owner = _a_config_f_owner;
	winwin_config _arg_config = _a_config;
	ww_ptr_create _result = winwin_create((int)_arg_x, (int)_arg_y, _arg_width, _arg_height, _arg_config);
	gml_ostream _out(_inout_ptr);
	_out.write<ww_ptr_create>(_result);
	return 1;
}

extern void winwin_destroy(ww_ptr_destroy ww);
dllx double winwin_destroy_raw(void* _in_ptr, double _in_ptr_size) {
	gml_istream _in(_in_ptr);
	ww_ptr_destroy _arg_ww = _in.read<ww_ptr_destroy>();
	winwin_destroy(_arg_ww);
	return 1;
}

extern bool winwin_get_topmost(ww_ptr ww);
dllx double winwin_get_topmost_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_topmost(_arg_ww);
}

extern bool winwin_set_topmost(ww_ptr ww, bool enable);
dllx double winwin_set_topmost_raw(winwin* _arg_ww, double _arg_enable) {
	// no buffer!
	return winwin_set_topmost(_arg_ww, (bool)_arg_enable);
}

extern bool winwin_order_after(ww_ptr ww, ww_ptr ref);
dllx double winwin_order_after_raw(winwin* _arg_ww, winwin* _arg_ref) {
	// no buffer!
	return winwin_order_after(_arg_ww, _arg_ref);
}

extern bool winwin_order_front(ww_ptr ww);
dllx double winwin_order_front_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_order_front(_arg_ww);
}

extern bool winwin_order_back(ww_ptr ww);
dllx double winwin_order_back_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_order_back(_arg_ww);
}

extern bool winwin_get_taskbar_button_visible(ww_ptr ww);
dllx double winwin_get_taskbar_button_visible_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_taskbar_button_visible(_arg_ww);
}

extern bool winwin_set_taskbar_button_visible(ww_ptr ww, bool show_button);
dllx double winwin_set_taskbar_button_visible_raw(winwin* _arg_ww, double _arg_show_button) {
	// no buffer!
	return winwin_set_taskbar_button_visible(_arg_ww, (bool)_arg_show_button);
}

extern bool winwin_get_clickthrough(ww_ptr ww);
dllx double winwin_get_clickthrough_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_clickthrough(_arg_ww);
}

extern bool winwin_set_clickthrough(ww_ptr ww, bool enable_clickthrough);
dllx double winwin_set_clickthrough_raw(winwin* _arg_ww, double _arg_enable_clickthrough) {
	// no buffer!
	return winwin_set_clickthrough(_arg_ww, (bool)_arg_enable_clickthrough);
}

extern bool winwin_get_noactivate(ww_ptr ww);
dllx double winwin_get_noactivate_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_noactivate(_arg_ww);
}

extern bool winwin_set_noactivate(ww_ptr ww, bool disable_activation);
dllx double winwin_set_noactivate_raw(winwin* _arg_ww, double _arg_disable_activation) {
	// no buffer!
	return winwin_set_noactivate(_arg_ww, (bool)_arg_disable_activation);
}

extern bool winwin_get_visible(ww_ptr ww);
dllx double winwin_get_visible_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_visible(_arg_ww);
}

extern bool winwin_set_visible(ww_ptr ww, bool visible);
dllx double winwin_set_visible_raw(winwin* _arg_ww, double _arg_visible) {
	// no buffer!
	return winwin_set_visible(_arg_ww, (bool)_arg_visible);
}

extern std::optional<int> winwin_get_cursor(ww_ptr ww);
dllx double winwin_get_cursor_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_cursor(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern bool winwin_set_cursor(ww_ptr ww, int cursor);
dllx double winwin_set_cursor_raw(winwin* _arg_ww, double _arg_cursor) {
	// no buffer!
	return winwin_set_cursor(_arg_ww, (int)_arg_cursor);
}

extern uintptr_t winwin_get_cursor_handle(ww_ptr ww);
dllx double winwin_get_cursor_handle_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	uintptr_t _result = winwin_get_cursor_handle(_arg_ww);
	gml_ostream _out(_inout_ptr);
	_out.write<uintptr_t>(_result);
	return 1;
}

extern bool winwin_set_cursor_handle(ww_ptr ww, uintptr_t hcursor);
dllx double winwin_set_cursor_handle_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_in_ptr);
	uintptr_t _arg_hcursor = _in.read<uintptr_t>();
	return winwin_set_cursor_handle(_arg_ww, _arg_hcursor);
}

extern bool winwin_resize_buffer(ww_ptr ww, int width, int height);
dllx double winwin_resize_buffer_raw(winwin* _arg_ww, double _arg_width, double _arg_height) {
	// no buffer!
	return winwin_resize_buffer(_arg_ww, (int)_arg_width, (int)_arg_height);
}

extern bool winwin_draw_begin_raw(ww_ptr ww);
dllx double winwin_draw_begin_raw_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_draw_begin_raw(_arg_ww);
}

extern bool winwin_has_focus(ww_ptr ww);
dllx double winwin_has_focus_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_has_focus(_arg_ww);
}

extern ww_ptr_find winwin_get_focus();
dllx double winwin_get_focus_raw(void* _inout_ptr, double _inout_ptr_size) {
	gml_istream _in(_inout_ptr);
	ww_ptr_find _result = winwin_get_focus();
	gml_ostream _out(_inout_ptr);
	_out.write<ww_ptr_find>(_result);
	return 1;
}

extern bool winwin_set_focus(ww_ptr ww);
dllx double winwin_set_focus_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_set_focus(_arg_ww);
}

extern bool winwin_keyboard_check(ww_ptr ww, int key);
dllx double winwin_keyboard_check_raw(winwin* _arg_ww, double _arg_key) {
	// no buffer!
	return winwin_keyboard_check(_arg_ww, (int)_arg_key);
}

extern bool winwin_keyboard_check_pressed(ww_ptr ww, int key);
dllx double winwin_keyboard_check_pressed_raw(winwin* _arg_ww, double _arg_key) {
	// no buffer!
	return winwin_keyboard_check_pressed(_arg_ww, (int)_arg_key);
}

extern bool winwin_keyboard_check_released(ww_ptr ww, int key);
dllx double winwin_keyboard_check_released_raw(winwin* _arg_ww, double _arg_key) {
	// no buffer!
	return winwin_keyboard_check_released(_arg_ww, (int)_arg_key);
}

extern const char* winwin_keyboard_get_string(ww_ptr ww);
dllx const char* winwin_keyboard_get_string_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_keyboard_get_string(_arg_ww);
}

extern int winwin_keyboard_set_string_raw(ww_ptr ww, gml_buffer buf);
dllx double winwin_keyboard_set_string_raw_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_in_ptr);
	gml_buffer _arg_buf = _in.read_gml_buffer();
	return winwin_keyboard_set_string_raw(_arg_ww, _arg_buf);
}

extern int winwin_keyboard_get_max_string_length(ww_ptr ww);
dllx double winwin_keyboard_get_max_string_length_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_keyboard_get_max_string_length(_arg_ww);
}

extern int winwin_keyboard_set_max_string_length(ww_ptr ww, int new_capacity);
dllx double winwin_keyboard_set_max_string_length_raw(winwin* _arg_ww, double _arg_new_capacity) {
	// no buffer!
	return winwin_keyboard_set_max_string_length(_arg_ww, (int)_arg_new_capacity);
}

extern bool winwin_mouse_is_over(ww_ptr ww);
dllx double winwin_mouse_is_over_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_mouse_is_over(_arg_ww);
}

extern int winwin_mouse_get_x(ww_ptr ww);
dllx double winwin_mouse_get_x_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_mouse_get_x(_arg_ww);
}

extern int winwin_mouse_get_y(ww_ptr ww);
dllx double winwin_mouse_get_y_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_mouse_get_y(_arg_ww);
}

extern bool winwin_mouse_check_button(ww_ptr ww, int button);
dllx double winwin_mouse_check_button_raw(winwin* _arg_ww, double _arg_button) {
	// no buffer!
	return winwin_mouse_check_button(_arg_ww, (int)_arg_button);
}

extern bool winwin_mouse_check_button_pressed(ww_ptr ww, int button);
dllx double winwin_mouse_check_button_pressed_raw(winwin* _arg_ww, double _arg_button) {
	// no buffer!
	return winwin_mouse_check_button_pressed(_arg_ww, (int)_arg_button);
}

extern bool winwin_mouse_check_button_released(ww_ptr ww, int button);
dllx double winwin_mouse_check_button_released_raw(winwin* _arg_ww, double _arg_button) {
	// no buffer!
	return winwin_mouse_check_button_released(_arg_ww, (int)_arg_button);
}

extern bool winwin_mouse_wheel_up(ww_ptr ww);
dllx double winwin_mouse_wheel_up_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_mouse_wheel_up(_arg_ww);
}

extern bool winwin_mouse_wheel_down(ww_ptr ww);
dllx double winwin_mouse_wheel_down_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_mouse_wheel_down(_arg_ww);
}

extern int winwin_mouse_wheel_get_delta_x(ww_ptr ww);
dllx double winwin_mouse_wheel_get_delta_x_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_mouse_wheel_get_delta_x(_arg_ww);
}

extern int winwin_mouse_wheel_get_delta_y(ww_ptr ww);
dllx double winwin_mouse_wheel_get_delta_y_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_mouse_wheel_get_delta_y(_arg_ww);
}

extern void winwin_keyboard_clear(ww_ptr ww, int key);
dllx double winwin_keyboard_clear_raw(winwin* _arg_ww, double _arg_key) {
	// no buffer!
	winwin_keyboard_clear(_arg_ww, (int)_arg_key);
	return 1;
}

extern void winwin_mouse_clear(ww_ptr ww, int button);
dllx double winwin_mouse_clear_raw(winwin* _arg_ww, double _arg_button) {
	// no buffer!
	winwin_mouse_clear(_arg_ww, (int)_arg_button);
	return 1;
}

extern void winwin_io_clear(ww_ptr ww);
dllx double winwin_io_clear_raw(winwin* _arg_ww) {
	// no buffer!
	winwin_io_clear(_arg_ww);
	return 1;
}

extern void winwin_sleep(int ms, bool process_messages);
dllx double winwin_sleep_raw(double _arg_ms, double _arg_process_messages) {
	// no buffer!
	winwin_sleep((int)_arg_ms, (bool)_arg_process_messages);
	return 1;
}

extern void winwin_game_end(int exit_code);
dllx double winwin_game_end_raw(double _arg_exit_code) {
	// no buffer!
	winwin_game_end((int)_arg_exit_code);
	return 1;
}

extern uintptr_t winwin_get_handle(ww_ptr ww);
dllx double winwin_get_handle_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	uintptr_t _result = winwin_get_handle(_arg_ww);
	gml_ostream _out(_inout_ptr);
	_out.write<uintptr_t>(_result);
	return 1;
}

extern const char* winwin_get_caption(ww_ptr ww);
dllx const char* winwin_get_caption_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_caption(_arg_ww);
}

extern bool winwin_set_caption(ww_ptr ww, const char* caption);
dllx double winwin_set_caption_raw(winwin* _arg_ww, const char* _arg_caption) {
	// no buffer!
	return winwin_set_caption(_arg_ww, _arg_caption);
}

extern int8_t winwin_get_close_button(ww_ptr ww);
dllx double winwin_get_close_button_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_close_button(_arg_ww);
}

extern bool winwin_set_close_button(ww_ptr ww, int8_t close_button_state);
dllx double winwin_set_close_button_raw(winwin* _arg_ww, double _arg_close_button_state) {
	// no buffer!
	return winwin_set_close_button(_arg_ww, (int8_t)_arg_close_button_state);
}

extern int8_t winwin_get_vsync(ww_ptr ww);
dllx double winwin_get_vsync_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_vsync(_arg_ww);
}

extern void winwin_set_vsync(ww_ptr ww, int sync_interval);
dllx double winwin_set_vsync_raw(winwin* _arg_ww, double _arg_sync_interval) {
	// no buffer!
	winwin_set_vsync(_arg_ww, (int)_arg_sync_interval);
	return 1;
}

extern ww_ptr_find winwin_get_owner(ww_ptr ww);
dllx double winwin_get_owner_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	ww_ptr_find _result = winwin_get_owner(_arg_ww);
	gml_ostream _out(_inout_ptr);
	_out.write<ww_ptr_find>(_result);
	return 1;
}

extern void winwin_set_owner(ww_ptr ww, std::optional<ww_ptr> owner);
dllx double winwin_set_owner_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_in_ptr);
	std::optional<ww_ptr> _a_owner;
	if (_in.read<bool>()) {
		_a_owner = (ww_ptr)_in.read<int64_t>();
	} else _a_owner = {};
	std::optional<ww_ptr> _arg_owner = _a_owner;
	winwin_set_owner(_arg_ww, _arg_owner);
	return 1;
}

extern std::optional<int> winwin_get_x(ww_ptr ww);
dllx double winwin_get_x_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_x(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern std::optional<int> winwin_get_y(ww_ptr ww);
dllx double winwin_get_y_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_y(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern std::optional<int> winwin_get_width(ww_ptr ww);
dllx double winwin_get_width_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_width(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern std::optional<int> winwin_get_height(ww_ptr ww);
dllx double winwin_get_height_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_height(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern bool winwin_set_position(ww_ptr ww, int x, int y);
dllx double winwin_set_position_raw(winwin* _arg_ww, double _arg_x, double _arg_y) {
	// no buffer!
	return winwin_set_position(_arg_ww, (int)_arg_x, (int)_arg_y);
}

extern bool winwin_set_size(ww_ptr ww, int width, int height);
dllx double winwin_set_size_raw(winwin* _arg_ww, double _arg_width, double _arg_height) {
	// no buffer!
	return winwin_set_size(_arg_ww, (int)_arg_width, (int)_arg_height);
}

extern bool winwin_set_rectangle(ww_ptr ww, int x, int y, int width, int height);
dllx double winwin_set_rectangle_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww, double _arg_x) {
	gml_istream _in(_in_ptr);
	int _arg_y = _in.read<int>();
	int _arg_width = _in.read<int>();
	int _arg_height = _in.read<int>();
	return winwin_set_rectangle(_arg_ww, (int)_arg_x, _arg_y, _arg_width, _arg_height);
}

extern std::optional<int> winwin_get_min_width(ww_ptr ww);
dllx double winwin_get_min_width_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_min_width(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern std::optional<int> winwin_get_min_height(ww_ptr ww);
dllx double winwin_get_min_height_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_min_height(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern std::optional<int> winwin_get_max_width(ww_ptr ww);
dllx double winwin_get_max_width_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_max_width(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern std::optional<int> winwin_get_max_height(ww_ptr ww);
dllx double winwin_get_max_height_raw(void* _inout_ptr, double _inout_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_inout_ptr);
	std::optional<int> _result = winwin_get_max_height(_arg_ww);
	gml_ostream _out(_inout_ptr);
	auto& _r = _result;
	if (_r.has_value()) {
		_out.write<bool>(true);
		_out.write<int>(_r.value());
	} else _out.write<bool>(false);
	return 1;
}

extern bool winwin_set_min_width(ww_ptr ww, std::optional<int> min_width);
dllx double winwin_set_min_width_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_in_ptr);
	std::optional<int> _arg_min_width;
	if (_in.read<bool>()) {
		std::optional<int> _a_min_width;
		if (_in.read<bool>()) {
			_a_min_width = _in.read<int>();
		} else _a_min_width = {};
		_arg_min_width = _a_min_width;
	} else _arg_min_width = {};
	return winwin_set_min_width(_arg_ww, _arg_min_width);
}

extern bool winwin_set_min_height(ww_ptr ww, std::optional<int> min_height);
dllx double winwin_set_min_height_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_in_ptr);
	std::optional<int> _arg_min_height;
	if (_in.read<bool>()) {
		std::optional<int> _a_min_height;
		if (_in.read<bool>()) {
			_a_min_height = _in.read<int>();
		} else _a_min_height = {};
		_arg_min_height = _a_min_height;
	} else _arg_min_height = {};
	return winwin_set_min_height(_arg_ww, _arg_min_height);
}

extern bool winwin_set_max_width(ww_ptr ww, std::optional<int> max_width);
dllx double winwin_set_max_width_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_in_ptr);
	std::optional<int> _arg_max_width;
	if (_in.read<bool>()) {
		std::optional<int> _a_max_width;
		if (_in.read<bool>()) {
			_a_max_width = _in.read<int>();
		} else _a_max_width = {};
		_arg_max_width = _a_max_width;
	} else _arg_max_width = {};
	return winwin_set_max_width(_arg_ww, _arg_max_width);
}

extern bool winwin_set_max_height(ww_ptr ww, std::optional<int> max_height);
dllx double winwin_set_max_height_raw(void* _in_ptr, double _in_ptr_size, winwin* _arg_ww) {
	gml_istream _in(_in_ptr);
	std::optional<int> _arg_max_height;
	if (_in.read<bool>()) {
		std::optional<int> _a_max_height;
		if (_in.read<bool>()) {
			_a_max_height = _in.read<int>();
		} else _a_max_height = {};
		_arg_max_height = _a_max_height;
	} else _arg_max_height = {};
	return winwin_set_max_height(_arg_ww, _arg_max_height);
}

extern bool winwin_is_minimized(ww_ptr ww);
dllx double winwin_is_minimized_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_is_minimized(_arg_ww);
}

extern bool winwin_is_maximized(ww_ptr ww);
dllx double winwin_is_maximized_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_is_maximized(_arg_ww);
}

extern bool winwin_syscommand(ww_ptr ww, int command);
dllx double winwin_syscommand_raw(winwin* _arg_ww, double _arg_command) {
	// no buffer!
	return winwin_syscommand(_arg_ww, (int)_arg_command);
}

extern double winwin_get_alpha(ww_ptr ww);
dllx double winwin_get_alpha_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_alpha(_arg_ww);
}

extern bool winwin_set_alpha(ww_ptr ww, double alpha);
dllx double winwin_set_alpha_raw(winwin* _arg_ww, double _arg_alpha) {
	// no buffer!
	return winwin_set_alpha(_arg_ww, _arg_alpha);
}

extern int winwin_get_chromakey(ww_ptr ww);
dllx double winwin_get_chromakey_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_chromakey(_arg_ww);
}

extern bool winwin_set_chromakey(ww_ptr ww, double color);
dllx double winwin_set_chromakey_raw(winwin* _arg_ww, double _arg_color) {
	// no buffer!
	return winwin_set_chromakey(_arg_ww, _arg_color);
}

extern bool winwin_enable_per_pixel_alpha(ww_ptr ww);
dllx double winwin_enable_per_pixel_alpha_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_enable_per_pixel_alpha(_arg_ww);
}

extern bool winwin_set_shadow(ww_ptr ww, bool enable);
dllx double winwin_set_shadow_raw(winwin* _arg_ww, double _arg_enable) {
	// no buffer!
	return winwin_set_shadow(_arg_ww, (bool)_arg_enable);
}

extern bool winwin_get_shadow(ww_ptr ww);
dllx double winwin_get_shadow_raw(winwin* _arg_ww) {
	// no buffer!
	return winwin_get_shadow(_arg_ww);
}

extern void winwin_update();
dllx double winwin_update_raw() {
	// no buffer!
	winwin_update();
	return 1;
}

// dllmain.cpp : Defines the entry point for the DLL application.
#include "stdafx.h"

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
					 )
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}

// stdafx.cpp : source file that includes just the standard includes
// winwin.pch will be the pre-compiled header
// stdafx.obj will contain the pre-compiled type information

#include "stdafx.h"

// TODO: reference any additional headers you need in STDAFX.H
// and not in this file
/// @author YellowAfterlife

#include "stdafx.h"
#include "winwin.h"
#include "winwin_config.h"

std::vector<winwin*> ww_list{};
std::unordered_map<HWND, winwin*> ww_map{};
wm_base_t ww_base{};
ww_ptr ww_main = nullptr;
StringConv ww_c1, ww_c2;
HCURSOR ww_base_cursor;

///
dllx double winwin_is_available() {
    return 1;
}

LRESULT CALLBACK winwin_wndproc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam);

constexpr wchar_t winwin_class[] = L"winwin_class";
HCURSOR winwin_cursor_init();
dllx double winwin_init_raw(void* hwnd, void* device, void* context, void* swapchain) {
    //
    ww_base.main_hwnd = (HWND)hwnd;
    ww_base.device = (ID3D11Device*)device;
    ww_base.context = (ID3D11DeviceContext*)context;
    ww_base.main_swapchain = (IDXGISwapChain*)swapchain;
    ww_base.hInstance = (HINSTANCE)GetWindowLongPtr(ww_base.main_hwnd, GWLP_HINSTANCE); // yeah dunno
    //
    WNDCLASSW wndc{};
    wndc.hInstance = ww_base.hInstance;
    wndc.lpszClassName = winwin_class;
    wndc.lpfnWndProc = winwin_wndproc;
    wndc.hIcon = (HICON)GetClassLongPtr(ww_base.main_hwnd, GCLP_HICON);
    RegisterClass(&wndc);
    //
    ww_main = new winwin();
    ww_main->hwnd = ww_base.main_hwnd;
    ww_main->swapchain = ww_base.main_swapchain;
    ww_base.ref = ww_main;
    //
    ww_base_cursor = winwin_cursor_init();
    //
    return 1;
}
///~
dllg ww_ptr_create winwin_init_2() {
    return ww_base.ref;
}

bool winwin_create_impl(winwin* ww, winwin_config& config, int x, int y, int width, int height) {
    DWORD dwExStyle = 0;
    DWORD dwStyle;
    ww->kind = config.kind;
    ww->has_shadow = config.kind != winwin_kind::borderless;
    if (config.kind == winwin_kind::borderless) {
        dwStyle = WS_POPUP;
        if (!config.taskbar_button) {
            dwExStyle |= WS_EX_TOOLWINDOW;
        }
    } else {
        dwStyle = WS_OVERLAPPEDWINDOW;
        if (!config.resize) dwStyle &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
        if (config.kind == winwin_kind::tool) {
            dwExStyle |= WS_EX_TOOLWINDOW;
        }
    }
    if (config.noactivate) dwExStyle |= WS_EX_NOACTIVATE;
    //
    RECT rcClient = { x, y, x + width, y + height };
    AdjustWindowRectEx(&rcClient, dwStyle, false, dwExStyle);
    //
    auto hwnd = CreateWindowExW(
        dwExStyle,
        winwin_class,
        ww_cc(config.caption),
        dwStyle,
        rcClient.left, rcClient.top, rect_width(rcClient), rect_height(rcClient),
        nullptr, nullptr, ww_base.hInstance, nullptr
    );
    if (hwnd == nullptr) return false;
    //
    if (config.close_button == 0) {
        auto menu = GetSystemMenu(hwnd, false);
        EnableMenuItem(menu, SC_CLOSE, MF_BYCOMMAND | MF_GRAYED);
    }
    //
    ww->hwnd = hwnd;
    ww->close_button = config.close_button;
    ww->buf.width = width;
    ww->buf.height = height;
    ww->buf.new_width = width;
    ww->buf.new_height = height;
    ww->cursor = ww_base_cursor;
    ww->sync_interval = config.vsync;

    ID3D11Device* device = ww_base.device;

    // swapchain:
    DXGI_SWAP_CHAIN_DESC scd = {};
    scd.BufferCount = 1;
    scd.BufferDesc.Format = ww_dxgi_format;
    scd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    scd.OutputWindow = ww->hwnd;
    scd.SampleDesc.Count = 1;
    scd.Windowed = TRUE;
    scd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    scd.Flags = 0x0;

    IDXGIDevice* dxgiDevice = nullptr;
    device->QueryInterface(__uuidof(IDXGIDevice), (void**)&dxgiDevice);

    IDXGIAdapter* adapter = nullptr;
    dxgiDevice->GetAdapter(&adapter);

    IDXGIFactory* factory = nullptr;
    adapter->GetParent(__uuidof(IDXGIFactory), (void**)&factory);

    factory->CreateSwapChain(device, &scd, &ww->swapchain);
    // not having DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH is not enough, you have to do this too:
    factory->MakeWindowAssociation(ww->hwnd, DXGI_MWA_NO_ALT_ENTER);

    dxgiDevice->Release();
    adapter->Release();
    factory->Release();

    // render target view:
    ID3D11Texture2D* pBackBuffer = nullptr;
    ww->swapchain->GetBuffer(0, __uuidof(ID3D11Texture2D), (void**)&pBackBuffer);
    if (pBackBuffer == nullptr) return false;

    device->CreateRenderTargetView(pBackBuffer, nullptr, &ww->rtv);
    pBackBuffer->Release();

    ww_list.push_back(ww);
    ww_map[ww->hwnd] = ww;
    
    if (config.owner) {
        void winwin_set_owner(ww_ptr ww, std::optional<ww_ptr> owner);
        winwin_set_owner(ww, config.owner);
    }
    if (config.per_pixel_alpha) {
        bool winwin_enable_per_pixel_alpha(ww_ptr ww);
        winwin_enable_per_pixel_alpha(ww);
    }
    if (config.show) ShowWindow(ww->hwnd, SW_SHOWNOACTIVATE);
    if (config.clickthrough) {
        if (config.show) {
            // aside: setting this before show
            bool winwin_set_clickthrough(ww_ptr ww, bool enable_clickthrough);
            winwin_set_clickthrough(ww, true);
        } else {
            trace("Can't set clickthrough on an invisible window!");
        }
    }
    if (config.topmost) SetWindowPos(ww->hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    return true;
}
DWORD WINAPI winwin_thread(void* param) {
    auto ww = (winwin*)param;
    auto cohr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    IsGUIThread(true);

    auto& cr = ww->init.rect;
    auto ok = winwin_create_impl(ww, *ww->init.config, cr.x, cr.y, cr.width, cr.height);

    if (ok) {
        ww->mt.section = new CRITICAL_SECTION();
        InitializeCriticalSection(ww->mt.section);
    }
    ww->init.ok = ok;
    SetEvent(ww->mt.ready);
    if (!ok) {
        CoUninitialize();
        return 0;
    }

    MSG msg{};
    while (GetMessage(&msg, ww->hwnd, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    CoUninitialize();
    return static_cast<DWORD>(msg.wParam);
}
dllg ww_ptr_create winwin_create(int x, int y, int width, int height, winwin_config config) {
    auto ww = new winwin();
    bool ok;
    if (config.thread) {
        //
        auto &ir = ww->init.rect;
        ir.x = x;
        ir.y = y;
        ir.width = width;
        ir.height = height;
        //
        ww->init.config = new winwin_config();
        static_assert(std::is_trivially_copyable_v<winwin_config>, "winwin_config must be trivially copyable");
        memcpy_arr(ww->init.config, &config, 1);
        //
        ww->mt.ready = CreateEvent(nullptr, TRUE, FALSE, nullptr);
        CreateThread(nullptr, 0, winwin_thread, ww, 0, &ww->mt.thread_id);
        WaitForSingleObject(ww->mt.ready, INFINITE);
        ok = ww->init.ok;
    } else {
        ok = winwin_create_impl(ww, config, x, y, width, height);
    }
    if (!ok) {
        delete ww;
        return nullptr;
    }
    return ww;
}
winwin::~winwin() {
    this->mt.enter();
    if (this->hwnd) {
        if (this->mt.section || this == ww_main) {
            // just tell it to close, I guess? We don't own the window
            this->close_button = 1;
            PostMessage(this->hwnd, WM_CLOSE, 0, 0);
        } else {
            DestroyWindow(this->hwnd);
        }
        this->hwnd = nullptr;
    }
    //
    if (this->init.config) {
        delete this->init.config;
        this->init.config = nullptr;
    }
    //
    auto& mt = this->mt;
    if (mt.ready) {
        CloseHandle(mt.ready);
        mt.ready = NULL;
    }
    if (mt.thread) {
        CloseHandle(mt.thread);
        mt.thread = NULL;
    }
    //
    this->rtv->Release();
    this->swapchain->Release();
    //
    auto section = this->mt.section;
    if (section) {
        this->mt.section = nullptr;
        LeaveCriticalSection(section);
        DeleteCriticalSection(section);
    }
}

dllx double winwin_draw_end_raw();
dllg void winwin_destroy(ww_ptr_destroy ww) {
    if (ww_target == ww) winwin_draw_end_raw();
    auto n = ww_list.size();
    for (auto i = 0u; i < n; i++) {
        if (ww_list[i] == ww) {
            ww_list.erase(ww_list.begin() + i);
            break;
        }
    }
    ww_map.erase(ww->hwnd);
    DestroyWindow(ww->hwnd);
    delete ww;
}

#include "stdafx.h"
#include "winwin.h"

/*
Consideration: 
struct {
    winwin* target = nullptr;
    double target_halign = 0, target_valign = 0;
    double self_halign = 0, self_valign = 0;
    std::vector<winwin*> attachments{};
} attach;
But would it be better if window automatically remembered its offset relative to parent?
Kind of complicated
*/#include "stdafx.h"
#include "winwin.h"

//
dllg bool winwin_get_topmost(ww_ptr ww) {
    auto hwnd = ww->hwnd;
    return (GetWindowLong(hwnd, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0;
}
dllg bool winwin_set_topmost(ww_ptr ww, bool enable) {
    auto hwnd = ww->hwnd;
    return SetWindowPos(hwnd, enable ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
}
dllg bool winwin_order_after(ww_ptr ww, ww_ptr ref) {
    return SetWindowPos(ww->hwnd, ref->hwnd, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
}
dllg bool winwin_order_front(ww_ptr ww) {
    return SetWindowPos(ww->hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
}
dllg bool winwin_order_back(ww_ptr ww) {
    return SetWindowPos(ww->hwnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
}

// the following come from window_commands
// https://github.com/YAL-GameMaker/window_commands

// todo: https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-itaskbarlist-addtab
dllg bool winwin_get_taskbar_button_visible(ww_ptr ww) {
    return (GetWindowLong(ww->hwnd, GWL_EXSTYLE) & WS_EX_TOOLWINDOW) == 0;
}
dllg bool winwin_set_taskbar_button_visible(ww_ptr ww, bool show_button) {
    auto hwnd = ww->hwnd;
    auto exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    if (show_button) {
        exStyle &= ~WS_EX_TOOLWINDOW;
    } else exStyle |= WS_EX_TOOLWINDOW;
    SetWindowLong(hwnd, GWL_EXSTYLE, exStyle);
    return true;
}

// https://stackoverflow.com/a/50245502
dllg bool winwin_get_clickthrough(ww_ptr ww) {
    auto hwnd = ww->hwnd;
    return (GetWindowLong(hwnd, GWL_EXSTYLE) & WW_WS_EX_CLICKTHROUGH) == WW_WS_EX_CLICKTHROUGH;
}
dllg bool winwin_set_clickthrough(ww_ptr ww, bool enable_clickthrough) {
    auto hwnd = ww->hwnd;
    auto exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    if (enable_clickthrough) {
        exStyle |= WW_WS_EX_CLICKTHROUGH;
    } else exStyle &= ~WW_WS_EX_CLICKTHROUGH;
    SetWindowLong(hwnd, GWL_EXSTYLE, exStyle);
    return true;
}

//
dllg bool winwin_get_noactivate(ww_ptr ww) {
    auto hwnd = ww->hwnd;
    return (GetWindowLong(hwnd, GWL_EXSTYLE) & WS_EX_NOACTIVATE) == WS_EX_NOACTIVATE;
}
dllg bool winwin_set_noactivate(ww_ptr ww, bool disable_activation) {
    auto hwnd = ww->hwnd;
    auto exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    if (disable_activation) {
        exStyle |= WS_EX_NOACTIVATE;
    } else exStyle &= ~WS_EX_NOACTIVATE;
    SetWindowLong(hwnd, GWL_EXSTYLE, exStyle);
    return true;
}

dllg bool winwin_get_visible(ww_ptr ww) {
    return IsWindowVisible(ww->hwnd);
}
dllg bool winwin_set_visible(ww_ptr ww, bool visible) {
    auto hwnd = ww->hwnd;
    ShowWindow(hwnd, visible ? SW_SHOWNOACTIVATE : SW_HIDE);
    return true;
}#include "stdafx.h"
#include "winwin.h"

static HCURSOR winwin_cursors[23]{};

HCURSOR winwin_cursor_init() {
	#define X(c) LoadCursor(NULL, c)
	auto& cr = winwin_cursors;
	auto arrow = X(IDC_ARROW);
	auto dont = X(IDC_NO);
	cr[0] = arrow; // cr_default 0
	cr[1] = NULL; // cr_none -1
	cr[2] = arrow; // cr_arrow -2
	cr[3] = X(IDC_CROSS); // cr_cross -3
	cr[4] = X(IDC_IBEAM); // cr_beam -4
	cr[6] = X(IDC_SIZENESW); // cr_size_nesw -6
	cr[7] = X(IDC_SIZENS); // cr_size_ns -7
	cr[8] = X(IDC_SIZENWSE); // cr_size_nwse -8
	cr[9] = X(IDC_SIZEWE); // cr_size_we -9
	cr[10] = X(IDC_UPARROW); // cr_uparrow -10
	cr[11] = X(IDC_WAIT); // cr_hourglass -11
	cr[12] = X(IDC_HAND); // cr_drag -12
	for (int i = 13; i <= 18; i++) cr[i] = dont;
	cr[19] = X(IDC_APPSTARTING); // cr_appstart -19
	cr[21] = X(IDC_HELP); // cr_handpoint -21
	cr[22] = X(IDC_SIZEALL); // cr_size_all -22
	#undef X
	return arrow;
}

dllg std::optional<int> winwin_get_cursor(ww_ptr ww) {
	auto cr = ww->cursor;
	for (int i = 0; i < std::size(winwin_cursors); i++) {
		if (winwin_cursors[i] == cr) return -i;
	}
	return {};
}
dllg bool winwin_set_cursor(ww_ptr ww, int cursor) {
	cursor = -cursor;
	if (cursor < 0 || cursor >= std::size(winwin_cursors)) return false;
	ww->cursor = winwin_cursors[cursor];
	if (ww->mouse_over) SetCursor(ww->cursor);
	return true;
}

dllg uintptr_t winwin_get_cursor_handle(ww_ptr ww) {
	return (uintptr_t)ww->cursor;
}
dllg bool winwin_set_cursor_handle(ww_ptr ww, uintptr_t hcursor) {
	ww->cursor = (HCURSOR)hcursor;
	return true;
}
#include "stdafx.h"
#include "winwin.h"
#define __RELFILE__ "winwin_draw"

ww_ptr ww_target = nullptr;

constexpr UINT ww_max_rtvs = 4;
struct {
    ID3D11RenderTargetView* rtvs[ww_max_rtvs]{};
    ID3D11DepthStencilView* stencil{};

    CD3D11_VIEWPORT viewports[4]{};
    UINT viewportCount = 0;

    D3D11_RECT scissorRects[4]{};
    UINT scissorCount = 0;
} ww_last;

void winwin_draw_store() {
    auto ctx = ww_base.context;
    ctx->OMGetRenderTargets(ww_max_rtvs, ww_last.rtvs, &ww_last.stencil);

    ww_last.viewportCount = (UINT)std::size(ww_last.viewports);
    ctx->RSGetViewports(&ww_last.viewportCount, ww_last.viewports);

    ww_last.scissorCount = (UINT)std::size(ww_last.scissorRects);
    ctx->RSGetScissorRects(&ww_last.scissorCount, ww_last.scissorRects);
}
void winwin_draw_restore() {
    auto ctx = ww_base.context;
    ctx->OMSetRenderTargets(ww_max_rtvs, ww_last.rtvs, ww_last.stencil);
    ctx->RSSetViewports(ww_last.viewportCount, ww_last.viewports);
    ctx->RSSetScissorRects(ww_last.scissorCount, ww_last.scissorRects);
}

struct {
    int width, height;
} ww_draw;
dllx double winwin_get_draw_width() {
    return ww_draw.width;
}
dllx double winwin_get_draw_height() {
    return ww_draw.height;
}

void winwin_draw_set(winwin* ww) {
    auto ctx = ww_base.context;

    ID3D11RenderTargetView* targets[ww_max_rtvs]{};
    targets[0] = ww->rtv;
    ctx->OMSetRenderTargets((UINT)std::size(targets), targets, nullptr);

    CD3D11_VIEWPORT vp(0.0f, 0.0f, (float)ww_draw.width, (float)ww_draw.height);
    ctx->RSSetViewports(1, &vp);

    D3D11_RECT scissorRect = { 0, 0, ww_draw.width, ww_draw.height };
    ctx->RSSetScissorRects(1, &scissorRect);
}

dllg bool winwin_resize_buffer(ww_ptr ww, int width, int height) {
    if (ww_target == ww) {
        trace("Can't resize buffer while drawing to it");
        return false;
    }
    // same size!
    if (width == ww->buf.width && height == ww->buf.height) return true;

    ww->rtv->Release();
    ww->rtv = nullptr;
    auto hr = ww->swapchain->ResizeBuffers(1, width, height, ww_dxgi_format, 0);
    if (hr != S_OK) {
        trace("ResizeBuffers failed, hr=0x%x", hr);
        return false;
    }

    ID3D11Texture2D* pBackBuffer = nullptr;
    hr = ww->swapchain->GetBuffer(0, __uuidof(ID3D11Texture2D), (void**)&pBackBuffer);
    if (pBackBuffer == nullptr) {
        trace("GetBuffer failed, hr=0x%x", hr);
        return false;
    }

    ww_base.device->CreateRenderTargetView(pBackBuffer, nullptr, &ww->rtv);
    pBackBuffer->Release();
    ww->buf.width = width;
    ww->buf.height = height;
    ww->buf.resize_in = 0;

    return hr == S_OK;
}

/// ~
dllg bool winwin_draw_begin_raw(ww_ptr ww) {
    if (ww_target != nullptr) {
        trace("Already drawing to a window!");
        return false;
    }
    ww_target = ww;

    // store state:
    winwin_draw_store();

    // get current size:
    #if 0
    RECT rcClient{};
    if (!GetClientRect(ww->hwnd, &rcClient)) return false;
    auto rcWidth = rcClient.right - rcClient.left;
    auto rcHeight = rcClient.bottom - rcClient.top;
    rcWidth = ww->buf.width;
    rcHeight = ww->buf.height;
    ww_draw.width = rcWidth;
    ww_draw.height = rcHeight;
    #endif
    ww_draw.width = ww->buf.width;
    ww_draw.height = ww->buf.height;

    // set targets:
    winwin_draw_set(ww);

    return true;
}
dllx double winwin_draw_sync_raw() {
    if (!ww_target) return 0;
    winwin_draw_set(ww_target);
    return 1;
}
dllx double winwin_draw_end_raw() {
    auto ww = ww_target;
    if (ww == nullptr) {
        trace("Not drawing to a window!");
        return false;
    }
    ww_target = nullptr;
    auto ctx = ww_base.context;

    winwin_draw_restore();

    auto hr = ww->swapchain->Present(ww->sync_interval, 0);
    if (hr == S_OK) {
        // OK!
    } else if (hr == DXGI_STATUS_OCCLUDED) {
        // TODO: should use DXGI_PRESENT_TEST..?
        // https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/dxgi-status
    } else {
        trace("SwapChain->Present() failed, hresult=%d (0x%x)", hr, hr);
    }
    return hr == S_OK;
}#include "stdafx.h"
#include "winwin.h"

dllg bool winwin_has_focus(ww_ptr ww) {
	return GetFocus() == ww->hwnd;
}
dllg ww_ptr_find winwin_get_focus() {
	return ww_find(GetFocus());
}
dllg bool winwin_set_focus(ww_ptr ww) {
	return SetFocus(ww->hwnd) != NULL;
}
#include "stdafx.h"
#include "winwin.h"

/** @dllg:gmlheader if (argument0 == winwin_main) return keyboard_check(argument1); */
dllg bool winwin_keyboard_check(ww_ptr ww, int key) {
	return ww->keys.down.get(key);
}
/** @dllg:gmlheader if (argument0 == winwin_main) return keyboard_check_pressed(argument1); */
dllg bool winwin_keyboard_check_pressed(ww_ptr ww, int key) {
	return ww->keys.pressed.get(key);
}
/** @dllg:gmlheader if (argument0 == winwin_main) return keyboard_check_released(argument1); */
dllg bool winwin_keyboard_check_released(ww_ptr ww, int key) {
	return ww->keys.released.get(key);
}

// // // keyboard string
void winwin_keyboard_string_proc(ww_ptr ww, uint32_t c) {
	auto& wks = ww->keyboard_string;
	if (wks.size >= wks.capacity) {
		wks.size = 0;
	}
	if (c == 8) {
		if (wks.size > 0) wks.size -= 1;
	} else if (c >= 32) {
		wks.data[wks.size++] = c;
	}
}
/** @dllg:gmlheader if (argument0 == winwin_main) return keyboard_string; */
dllg const char* winwin_keyboard_get_string(ww_ptr ww) {
	static std::vector<uint8_t> result{};
	auto& wks = ww->keyboard_string;
	auto size = wks.size;
	auto chars = wks.data;
	result.resize(size * 4 + 1);
	auto r = result.data();
	for (int i = 0; i < size; i++) {
		auto c = chars[i];
		if (c < 128) {
			r[0] = (char)c;
			r += 1;
		} else if (c < 2048) {
			r[0] = 0xC0 + ((c >> 6) & 0x1F);
			r[1] = 0x80 + ( c       & 0x3F);
			r += 2;
		} else if (c < 65536) {
			r[0] = 0xE0 + ((c >> 12) & 0x0F);
			r[1] = 0x80 + ((c >>  6) & 0x3F);
			r[2] = 0x80 + ( c        & 0x3F);
			r += 3;
		} else {
			r[0] = 0xF0 + ((c >> 18) & 0x07);
			r[1] = 0x80 + ((c >> 12) & 0x3F);
			r[2] = 0x80 + ((c >>  6) & 0x3F);
			r[3] = 0x80 + ( c        & 0x3F);
			r += 4;
		}
	}
	r[0] = 0;
	return (const char*)result.data();
}
/// ~
dllg int winwin_keyboard_set_string_raw(ww_ptr ww, gml_buffer buf) {
	auto& wks = ww->keyboard_string;
	auto n = buf.tell() >> 2;
	if (n > wks.capacity) n = wks.capacity;
	memcpy_arr(wks.data, (uint32_t*)buf.data(), n);
	wks.size = n;
	return n;
}
/** @dllg:gmlheader if (argument0 == winwin_main) return 1024; */
dllg int winwin_keyboard_get_max_string_length(ww_ptr ww) {
	return ww->keyboard_string.capacity;
}
/** @dllg:gmlheader if (argument0 == winwin_main) return false; */
dllg int winwin_keyboard_set_max_string_length(ww_ptr ww, int new_capacity) {
	auto& wks = ww->keyboard_string;
	wks.capacity = new_capacity;
	wks.data = realloc_arr(wks.data, new_capacity);
	if (wks.size > wks.capacity) wks.size = wks.capacity;
	return true;
}

// // // mouse

dllg bool winwin_mouse_is_over(ww_ptr ww) {
	return ww->mouse_over;
}

/** @dllg:gmlheader if (argument0 == winwin_main) return window_mouse_get_x(); */
dllg int winwin_mouse_get_x(ww_ptr ww) {
	return ww->mouse_x;
}
/** @dllg:gmlheader if (argument0 == winwin_main) return window_mouse_get_y(); */
dllg int winwin_mouse_get_y(ww_ptr ww) {
	return ww->mouse_y;
}

/** @dllg:gmlheader if (argument0 == winwin_main) return mouse_check_button(argument1); */
dllg bool winwin_mouse_check_button(ww_ptr ww, int button) {
	return ww->mouse.down.get(button);
}
/** @dllg:gmlheader if (argument0 == winwin_main) return mouse_check_button_pressed(argument1); */
dllg bool winwin_mouse_check_button_pressed(ww_ptr ww, int button) {
	return ww->mouse.pressed.get(button);
}
/** @dllg:gmlheader if (argument0 == winwin_main) return mouse_check_button_released(argument1); */
dllg bool winwin_mouse_check_button_released(ww_ptr ww, int button) {
	return ww->mouse.released.get(button);
}

/** @dllg:gmlheader if (argument0 == winwin_main) return mouse_wheel_up(); */
dllg bool winwin_mouse_wheel_up(ww_ptr ww) {
	return ww->mouse.wheel < 0;
}
/** @dllg:gmlheader if (argument0 == winwin_main) return mouse_wheel_down(); */
dllg bool winwin_mouse_wheel_down(ww_ptr ww) {
	return ww->mouse.wheel > 0;
}
/** @dllg:gmlheader if (argument0 == winwin_main) return 0; */
dllg int winwin_mouse_wheel_get_delta_x(ww_ptr ww) {
	return ww->mouse.hwheel;
}
/** @dllg:gmlheader if (argument0 == winwin_main) return mouse_wheel_down() - mouse_wheel_up(); */
dllg int winwin_mouse_wheel_get_delta_y(ww_ptr ww) {
	return ww->mouse.wheel;
}

dllg void winwin_keyboard_clear(ww_ptr ww, int key) {
	ww->keys.down.set(key, false);
	ww->keys.pressed.set(key, false);
	ww->keys.released.set(key, false);
	//
	ww->keys_next.down.set(key, false);
	ww->keys_next.pressed.set(key, false);
	ww->keys_next.released.set(key, false);
}
dllg void winwin_mouse_clear(ww_ptr ww, int button) {
	ww->mouse.down.set(button, false);
	ww->mouse.pressed.set(button, false);
	ww->mouse.released.set(button, false);
	//
	ww->mouse_next.down.set(button, false);
	ww->mouse_next.pressed.set(button, false);
	ww->mouse_next.released.set(button, false);
}
dllg void winwin_io_clear(ww_ptr ww) {
	ww->keys.down.clear();
	ww->keys.pressed.clear();
	ww->keys.released.clear();
	//
	ww->keys_next.down.clear();
	ww->keys_next.pressed.clear();
	ww->keys_next.released.clear();
	//
	ww->mouse.down.clear();
	ww->mouse.pressed.clear();
	ww->mouse.released.clear();
	//
	ww->mouse_next.down.clear();
	ww->mouse_next.pressed.clear();
	ww->mouse_next.released.clear();
}#include "stdafx.h"
#include "winwin.h"

void ProcessMessages() {
    tagMSG m;
    while (true) {
        if (PeekMessageW(&m, NULL, 0, 0, PM_REMOVE)) {
            if (m.message != WM_QUIT) {
                TranslateMessage(&m);
                DispatchMessageW(&m);
            } else break;
        } else break;
    }
}
dllg void winwin_sleep(int ms, bool process_messages = true) {
    if (!process_messages) {
        Sleep(ms);
        return;
    }
    constexpr int pm_step = 100;
    while (ms > 0) {
        int step;
        if (ms > pm_step) {
            step = pm_step;
            ms -= pm_step;
        } else {
            step = ms;
            ms = 0;
        }
        Sleep(step);
        ProcessMessages();
    }
}

dllg void winwin_game_end(int exit_code = 0) {
    exit(exit_code);
}#include "stdafx.h"
#include "winwin.h"
#define __RELFILE__ "winwin_props"

dllx double winwin_exists_raw(winwin* ww) {
    return IsWindow(ww->hwnd);
}
dllg uintptr_t winwin_get_handle(ww_ptr ww) {
    return (uintptr_t)ww->hwnd;
}

dllg const char* winwin_get_caption(ww_ptr ww) {
    auto len = GetWindowTextLengthW(ww->hwnd);
    if (len <= 0) return "";
    auto ws = ww_c1.wget(len + 1);
    memset(ws, 0, sizeof(wchar_t) * (len + 1));
    GetWindowTextW(ww->hwnd, ws, len + 1);
    return ww_cc(ws);
}
dllg bool winwin_set_caption(ww_ptr ww, const char* caption) {
    return SetWindowTextW(ww->hwnd, ww_cc(caption));
}

dllg int8_t winwin_get_close_button(ww_ptr ww) {
    return ww->close_button;
}
dllg bool winwin_set_close_button(ww_ptr ww, int8_t close_button_state) {
    auto hwnd = ww->hwnd;
    if (!hwnd) return false;
    auto curr = ww->close_button;
    if (curr == close_button_state) return true;
    ww->close_button = close_button_state;
    if ((curr == 0) != (close_button_state == 0)) {
        auto menu = GetSystemMenu(hwnd, false);
        return EnableMenuItem(menu, SC_CLOSE, MF_BYCOMMAND | (close_button_state == 0 ? MF_GRAYED : MF_ENABLED));
    }
    return true;
}

dllg int8_t winwin_get_vsync(ww_ptr ww) {
    return ww->sync_interval;
}
dllg void winwin_set_vsync(ww_ptr ww, int sync_interval) {
    ww->sync_interval = sync_interval;
}

dllg ww_ptr_find winwin_get_owner(ww_ptr ww) {
    auto val = GetWindowLongPtr(ww->hwnd, GWLP_HWNDPARENT);
    return ww_find((HWND)val);
}
dllg void winwin_set_owner(ww_ptr ww, std::optional<ww_ptr> owner) {
    SetWindowLongPtr(ww->hwnd, GWLP_HWNDPARENT, (LONG_PTR)(owner ? (*owner)->hwnd : NULL));
}#include "stdafx.h"
#include "winwin.h"

// getters:
#define winwin_def_rect_ret {}
dllg std::optional<int> winwin_get_x(ww_ptr ww) {
    RECT r{};
    if (!GetClientRect(ww->hwnd, &r)) return winwin_def_rect_ret;
    POINT p = { r.left, r.top };
    if (!ClientToScreen(ww->hwnd, &p)) return winwin_def_rect_ret;
    return p.x;
}
dllg std::optional<int> winwin_get_y(ww_ptr ww) {
    RECT r{};
    if (!GetClientRect(ww->hwnd, &r)) return winwin_def_rect_ret;
    POINT p = { r.left, r.top };
    if (!ClientToScreen(ww->hwnd, &p)) return winwin_def_rect_ret;
    return p.y;
}
dllg std::optional<int> winwin_get_width(ww_ptr ww) {
    RECT r{};
    if (GetClientRect(ww->hwnd, &r)) return rect_width(r);
    return winwin_def_rect_ret;
}
dllg std::optional<int> winwin_get_height(ww_ptr ww) {
    RECT r{};
    if (GetClientRect(ww->hwnd, &r)) return rect_height(r);
    return winwin_def_rect_ret;
}

// setters:
dllg bool winwin_set_position(ww_ptr ww, int x, int y) {
    RECT r{};
    if (!GetClientRect(ww->hwnd, &r)) return false;
    POINT p = { r.left, r.top };
    if (!ClientToScreen(ww->hwnd, &p)) return false;
    //
    if (!GetWindowRect(ww->hwnd, &r)) return false;
    int nx = r.left + (x - p.x);
    int ny = r.top + (y - p.y);
    //
    return SetWindowPos(ww->hwnd, 0, nx, ny, 0, 0, SWP_NOZORDER | SWP_NOSIZE | SWP_NOACTIVATE);
}

dllg bool winwin_set_size(ww_ptr ww, int width, int height) {
    auto hwnd = ww->hwnd;

    auto dwStyle = GetWindowLong(hwnd, GWL_STYLE);
    if (ww->kind == winwin_kind::borderless) dwStyle &= ~WS_CAPTION;
    auto dwExStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    auto hasMenu = GetMenu(hwnd) != NULL;
    RECT r = { 0, 0, width, height };
    if (!AdjustWindowRectEx(&r, dwStyle, hasMenu, dwExStyle)) return false;
    auto adjWidth = rect_width(r);
    auto adjHeight = rect_height(r);

    return SetWindowPos(hwnd, NULL, 0, 0, adjWidth, adjHeight, SWP_NOZORDER | SWP_NOMOVE | SWP_NOACTIVATE);
}

dllg bool winwin_set_rectangle(ww_ptr ww, int x, int y, int width, int height) {
    auto hwnd = ww->hwnd;

    auto dwStyle = GetWindowLong(hwnd, GWL_STYLE);
    if (ww->kind == winwin_kind::borderless) dwStyle &= ~WS_CAPTION;
    auto dwExStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    auto hasMenu = GetMenu(hwnd) != NULL;
    RECT r = { x, y, x + width, y + height };
    if (!AdjustWindowRectEx(&r, dwStyle, hasMenu, dwExStyle)) return false;
    auto adjWidth = rect_width(r);
    auto adjHeight = rect_height(r);

    return SetWindowPos(hwnd, NULL, r.left, r.top, adjWidth, adjHeight, SWP_NOZORDER | SWP_NOACTIVATE);
}

// min/max:
dllg std::optional<int> winwin_get_min_width(ww_ptr ww) {
    return ww->minSize.width;
}
dllg std::optional<int> winwin_get_min_height(ww_ptr ww) {
    return ww->minSize.height;
}
dllg std::optional<int> winwin_get_max_width(ww_ptr ww) {
    return ww->maxSize.width;
}
dllg std::optional<int> winwin_get_max_height(ww_ptr ww) {
    return ww->maxSize.height;
}

dllg bool winwin_set_min_width(ww_ptr ww, std::optional<int> min_width = {}) {
    ww->minSize.width = min_width;
    return true;
}
dllg bool winwin_set_min_height(ww_ptr ww, std::optional<int> min_height = {}) {
    ww->minSize.height = min_height;
    return true;
}
dllg bool winwin_set_max_width(ww_ptr ww, std::optional<int> max_width = {}) {
    ww->maxSize.width = max_width;
    return true;
}
dllg bool winwin_set_max_height(ww_ptr ww, std::optional<int> max_height = {}) {
    ww->maxSize.height = max_height;
    return true;
}

// state:
dllg bool winwin_is_minimized(ww_ptr ww) {
    return IsIconic(ww->hwnd);
}
dllg bool winwin_is_maximized(ww_ptr ww) {
    WINDOWPLACEMENT wpl{};
    wpl.length = sizeof(wpl);
    if (!GetWindowPlacement(ww->hwnd, &wpl)) return false;
    return wpl.showCmd == SW_MAXIMIZE;
}
///~
dllg bool winwin_syscommand(ww_ptr ww, int command) {
    return SendMessage(ww->hwnd, WM_SYSCOMMAND, command, 0);
}
#include "stdafx.h"
#include "winwin.h"
#include <dwmapi.h>

// this largely mirrors my own window_shape

static LONG GetWindowExStyle(HWND hwnd) {
	return GetWindowLong(hwnd, GWL_EXSTYLE);
}
static void SetWindowExStyle(HWND hwnd, LONG flags) {
	SetWindowLong(hwnd, GWL_EXSTYLE, (flags));
}
static bool GetWindowLayered(HWND hwnd) {
	return GetWindowExStyle(hwnd) & WS_EX_LAYERED;
}
static void SetWindowLayered(HWND hwnd, bool layered) {
	auto flags = GetWindowExStyle(hwnd);
	if (layered) {
		if ((flags & WS_EX_LAYERED) == 0) {
			SetWindowExStyle(hwnd, flags | WS_EX_LAYERED);
		}
	} else {
		if ((flags & WS_EX_LAYERED) != 0) {
			SetWindowExStyle(hwnd, flags & ~WS_EX_LAYERED);
		}
	}
}

dllg double winwin_get_alpha(ww_ptr ww) {
	auto hwnd = ww->hwnd;
	if (!GetWindowLayered(hwnd)) return 1;
	BYTE alpha = 0;
	DWORD flags = 0;
	GetLayeredWindowAttributes(hwnd, NULL, &alpha, &flags);
	if ((flags & LWA_ALPHA) == 0) return 1;
	return (double)alpha / 255;
}
dllg bool winwin_set_alpha(ww_ptr ww, double alpha) {
	auto hwnd = ww->hwnd;
	bool set = alpha < 1;
	if (set) {
		SetWindowLayered(hwnd, true);
	} else {
		if (!GetWindowLayered(hwnd)) return true;
	}
	//
	BYTE bAlpha = 0;
	COLORREF crKey = {};
	DWORD flags = 0;
	GetLayeredWindowAttributes(hwnd, &crKey, &bAlpha, &flags);
	//
	if (set) {
		flags |= LWA_ALPHA;
		if (alpha < 0) alpha = 0;
		bAlpha = (BYTE)(alpha * 255);
		SetLayeredWindowAttributes(hwnd, crKey, bAlpha, flags);
	} else {
		flags &= ~LWA_ALPHA;
		SetLayeredWindowAttributes(hwnd, crKey, 255, flags);
		if (flags == 0) SetWindowLayered(hwnd, false);
	}
	return true;
}

dllg int winwin_get_chromakey(ww_ptr ww) {
	auto hwnd = ww->hwnd;
	if (!GetWindowLayered(hwnd)) return -1;
	COLORREF crKey;
	DWORD flags = 0;
	GetLayeredWindowAttributes(hwnd, &crKey, NULL, &flags);
	if ((flags & LWA_COLORKEY) == 0) return -1;
	return crKey;
}
dllg bool winwin_set_chromakey(ww_ptr ww, double color) {
	auto hwnd = ww->hwnd;
	bool set = color >= 0;
	if (set) {
		SetWindowLayered(hwnd, true);
	} else {
		if (!GetWindowLayered(hwnd)) return true;
	}
	//
	BYTE bAlpha = 0;
	COLORREF crKey = {};
	DWORD flags = 0;
	GetLayeredWindowAttributes(hwnd, &crKey, &bAlpha, &flags);
	//
	if (set) {
		flags |= LWA_COLORKEY;
		crKey = (DWORD)color;
		SetLayeredWindowAttributes(hwnd, crKey, bAlpha, flags);
	} else {
		flags &= ~LWA_COLORKEY;
		crKey = 0xFF00FF;
		SetLayeredWindowAttributes(hwnd, crKey, bAlpha, flags);
		if (flags == 0) SetWindowLayered(hwnd, false);
	}
	return true;
}

dllg bool winwin_enable_per_pixel_alpha(ww_ptr ww) {
	DWM_BLURBEHIND bb = { 0 };
	bb.dwFlags = DWM_BB_ENABLE | DWM_BB_BLURREGION;
	bb.hRgnBlur = CreateRectRgn(0, 0, -1, -1);
	bb.fEnable = TRUE;
	DwmEnableBlurBehindWindow(ww->hwnd, &bb);
	return 1;
}

dllg bool winwin_set_shadow(ww_ptr ww, bool enable) {
	if (ww->kind != winwin_kind::borderless) return false;
	ww->has_shadow = enable;
	auto hwnd = ww->hwnd;
	//
	auto pad = enable ? 1 : 0;
	MARGINS m{ pad, pad, pad, pad };
	DwmExtendFrameIntoClientArea(hwnd, &m);
	//
	auto style = GetWindowLong(hwnd, GWL_STYLE);
	if (enable) {
		style |= WS_CAPTION;
	} else style &= ~WS_CAPTION;
	SetWindowLong(hwnd, GWL_STYLE, style);
	//
	SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED);
	return true;
}
dllg bool winwin_get_shadow(ww_ptr ww) {
	return ww->has_shadow;
}#include "stdafx.h"
#include "winwin.h"

bool winwin_resize_buffer(ww_ptr ww, int width, int height);
dllg void winwin_update() {
    for (auto ww : ww_list) {
        ww->mt.enter();
        if (ww->buf.resize_in > 0 && --ww->buf.resize_in <= 0) {
            winwin_resize_buffer(ww, ww->buf.new_width, ww->buf.new_height);
        }
        //
        ww->keys.down.assign(ww->keys_next.down);
        ww->keys.pressed.assign(ww->keys_next.pressed);
        ww->keys_next.pressed.clear();
        ww->keys.released.assign(ww->keys_next.released);
        ww->keys_next.released.clear();
        //
        ww->mouse.down.assign(ww->mouse_next.down);
        ww->mouse.pressed.assign(ww->mouse_next.pressed);
        ww->mouse_next.pressed.clear();
        ww->mouse.released.assign(ww->mouse_next.released);
        ww->mouse_next.released.clear();
        ww->mouse.wheel = ww->mouse_next.wheel;
        ww->mouse_next.wheel = 0;
        ww->mouse.hwheel = ww->mouse_next.hwheel;
        ww->mouse_next.hwheel = 0;
        //
        ww->mt.leave();
    }
}#include "stdafx.h"
#include "winwin.h"
#include <windowsx.h>
//#include "WM_NAME.h"
#define __RELFILE__ "winwin_wndproc"

LRESULT CALLBACK winwin_wndproc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
    auto ww = ww_find(hwnd);
    if (!ww) { // ..?
        return DefWindowProc(hwnd, msg, wparam, lparam);
    }
    ww->mt.enter();
    #define mt_return(value) { ww->mt.leave(); return value; }
    #if 0
    bool print = false;
    switch (msg) {
        case WM_NCHITTEST:
        case WM_MOUSEMOVE:
        case WM_NCMOUSEMOVE:
        case WM_SETCURSOR:
            break;
        default:
            print = true;
            auto name = WM_NAME(msg);
            if (name == nullptr) name = "?";
            trace("msg=%s (%x) wp=%llx lp=%llx", name, msg, wparam, lparam);
            break;
    }
    #endif
    ww->mt.leave();
    switch (msg) {
        case WM_DESTROY: {
            if (ww->mt.section != nullptr) {
                PostQuitMessage(0);
                mt_return(0);
            }
        }; break;

        case WM_NCCALCSIZE: if (ww->kind == winwin_kind::borderless) {
            if (ww->has_shadow && wparam == TRUE) {
                SetWindowLong(hwnd, DWLP_MSGRESULT, 0);
                mt_return(TRUE);
            } else mt_return(FALSE);
        }; break;
        case WM_SIZE: {
            if (wparam == SIZE_MINIMIZED) {
                ww->buf.resize_in = 0;
            } else {
                if (wparam == SIZE_RESTORED) {
                    ww->buf.resize_in = 1;
                } else ww->buf.resize_in = 5;
                ww->buf.new_width = LOWORD(lparam);
                ww->buf.new_height = HIWORD(lparam);
            }
        }; break;
        case WM_GETMINMAXINFO: {
            RECT clientRect{};
            GetClientRect(hwnd, &clientRect);
            if (rect_width(clientRect) > 0) {
                RECT windowRect{};
                GetWindowRect(hwnd, &windowRect);
                auto dx = rect_width(windowRect) - clientRect.right;
                auto dy = rect_height(windowRect) - clientRect.bottom;

                auto inf = (MINMAXINFO*)lparam;
                if (ww->minSize.width)  inf->ptMinTrackSize.x = dx + *ww->minSize.width;
                if (ww->minSize.height) inf->ptMinTrackSize.y = dy + *ww->minSize.height;
                if (ww->maxSize.width)  inf->ptMaxTrackSize.x = dx + *ww->maxSize.width;
                if (ww->maxSize.height) inf->ptMaxTrackSize.y = dy + *ww->maxSize.height;
            }
        }; break;

        case WM_SYSCOMMAND: {
            if (wparam == SC_CLOSE && ww->close_button == 2) {
                ShowWindow(hwnd, SW_HIDE);
                mt_return(0);
            }
        }; break;
        
        // mouse:
        case WM_SETCURSOR: {
            if (LOWORD(lparam) != HTCLIENT) break;
            SetCursor(ww->cursor);
        }; break;
        case WM_MOUSEMOVE: {
            ww->mouse_x = GET_X_LPARAM(lparam);
            ww->mouse_y = GET_Y_LPARAM(lparam);
            if (!ww->mouse_tracking) {
                TRACKMOUSEEVENT tme{};
                tme.cbSize = sizeof(tme);
                tme.dwFlags = TME_LEAVE;
                tme.hwndTrack = hwnd;
                ww->mouse_tracking = TrackMouseEvent(&tme);
                //trace("Enter");
                if (ww->mouse_tracking) {
                    ww->mouse_over = true;
                }
            }
        }; break;
        case WM_MOUSELEAVE: {
            ww->mouse_tracking = false;
            //trace("Leave");
            ww->mouse_over = false;
        }; break;
        case WM_LBUTTONDOWN: case WM_RBUTTONDOWN: case WM_MBUTTONDOWN: {
            uint8_t flag = 0;
            switch (msg) {
                case WM_LBUTTONDOWN: flag = 1; break;
                case WM_RBUTTONDOWN: flag = 2; break;
                case WM_MBUTTONDOWN: flag = 3; break;
            }
            if (!ww->mouse_next.down.get(flag)) {
                ww->mouse_next.down.set(flag, true);
                ww->mouse_next.pressed.set(flag, true);
            }
            if (++ww->mouse_buttons_held == 1) SetCapture(ww->hwnd);
        }; break;
        case WM_LBUTTONUP: case WM_RBUTTONUP: case WM_MBUTTONUP:
        case WM_NCLBUTTONUP: case WM_NCRBUTTONUP: case WM_NCMBUTTONUP: {
            uint8_t flag = 0;
            switch (msg) {
                case WM_LBUTTONUP: case WM_NCLBUTTONUP: flag = 1; break;
                case WM_RBUTTONUP: case WM_NCRBUTTONUP: flag = 2; break;
                case WM_MBUTTONUP: case WM_NCMBUTTONUP: flag = 3; break;
            }
            if (ww->mouse_next.down.get(flag)) {
                ww->mouse_next.down.set(flag, false);
                ww->mouse_next.released.set(flag, true);
            }
            if (--ww->mouse_buttons_held <= 0) ReleaseCapture();
        }; break;
        case WM_MOUSEWHEEL: {
            ww->mouse_next.wheel -= (int)GET_WHEEL_DELTA_WPARAM(wparam);
        }; break;
        case WM_MOUSEHWHEEL: {
            ww->mouse_next.hwheel += (int)GET_WHEEL_DELTA_WPARAM(wparam);
        }; break;

        // keyboard:
        case WM_KEYDOWN: case WM_SYSKEYDOWN: {
            auto key = (int)wparam;
            if (key < 256 && !ww->keys_next.down.get(key)) {
                ww->keys_next.down.set(key, true);
                ww->keys_next.pressed.set(key, true);
            }
        }; break;
        case WM_KEYUP: case WM_SYSKEYUP: {
            auto key = (int)wparam;
            if (key < 256 && ww->keys_next.down.get(key)) {
                ww->keys_next.down.set(key, false);
                ww->keys_next.released.set(key, true);
            }
        }; break;
        case WM_CHAR: {
            void winwin_keyboard_string_proc(ww_ptr ww, uint32_t c);
            winwin_keyboard_string_proc(ww, (uint32_t)wparam);
        }; break;
    }
    ww->mt.leave();
    return DefWindowProc(hwnd, msg, wparam, lparam);
}