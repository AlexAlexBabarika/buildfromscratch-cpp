#include "bfspp/move.h"

template <class T>
constexpr T&& bfspp::move(T& t) {
    return static_cast<T&&>(t);
}

template <class T>
constexpr T&& move(T&& t) {
    return static_cast<T&&>(t);
}
