/// C++11 binary literal templates
/// @code
/// auto signed_value = 10001010_sbin;
/// auto unsigned_value = 11100000_bin;
/// @endcode
/// 
/// Taken from my answer here: https://stackoverflow.com/a/53702658/1353336
#include <cstdint>
#include <type_traits>

/// User-defined binary literal for C++11
/// @see https://stackoverflow.com/a/538101 / https://gist.github.com/lichray/4153963
/// @see https://stackoverflow.com/a/17229703
namespace detail {

template<class tValueType, char... digits>
struct binary_literal;

template<char... digits>
struct unsigned_binary_literal
{
    using Type = typename std::conditional<sizeof...(digits) <= 8, uint8_t,
                    typename std::conditional<sizeof...(digits) <= 16, uint16_t,
                        typename std::conditional<sizeof...(digits) <= 32, uint32_t, uint64_t>::type
                    >::type
                >::type;
};

template<char... digits>
struct signed_binary_literal
{
    using Type = typename std::conditional<sizeof...(digits) <= 8, int8_t,
                    typename std::conditional<sizeof...(digits) <= 16, int16_t,
                        typename std::conditional<sizeof...(digits) <= 32, int32_t, int64_t>::type
                    >::type
                >::type;
};

template<class tValueType, char high, char... digits>
struct binary_literal<tValueType, high, digits...>
{
    static constexpr tValueType value = (static_cast<tValueType>(high == '1') << (sizeof...(digits))) ^ binary_literal<tValueType, digits...>::value;
};

template<class tValueType, char high>
struct binary_literal<tValueType, high>
{
    static constexpr tValueType value = (high == '1');
};
} // namespace detail

/// C++11 support for binary literal
/// @tparam digits to transform to an unsigned integer
template<char... digits>
constexpr auto operator "" _bin() -> typename detail::unsigned_binary_literal<digits...>::Type
{
    return detail::binary_literal<typename detail::unsigned_binary_literal<digits...>::Type, digits...>::value;
}

/// C++11 support for binary literal
/// @tparam digits to transform to a signed integer
template<char... digits>
constexpr auto operator "" _sbin() -> typename detail::signed_binary_literal<digits...>::Type
{
    return static_cast<typename detail::signed_binary_literal<digits...>::Type>(detail::binary_literal<typename detail::unsigned_binary_literal<digits...>::Type, digits...>::value);
}
