////////////////////////////////////////////////////////////
//
// SFML - Simple and Fast Multimedia Library
// Copyright (C) 2007-2015 Laurent Gomila (laurent@sfml-dev.org)
//
// This software is provided 'as-is', without any express or implied warranty.
// In no event will the authors be held liable for any damages arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it freely,
// subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented;
//    you must not claim that you wrote the original software.
//    If you use this software in a product, an acknowledgment
//    in the product documentation would be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such,
//    and must not be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source distribution.
//
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Headers
////////////////////////////////////////////////////////////
#include <SFML/System/Win32/ClockImpl.hpp>
#include <windows.h>


namespace
{
    LARGE_INTEGER getFrequency()
    {
        LARGE_INTEGER frequency;
        QueryPerformanceFrequency(&frequency);
        return frequency;
    }
}

namespace sf
{
namespace priv
{
////////////////////////////////////////////////////////////
Time ClockImpl::getCurrentTime()
{
    // Get the frequency of the performance counter
    // (it is constant across the program lifetime)
    static LARGE_INTEGER frequency = getFrequency();

    // On Windows XP or older, timer inconsistencies might
    // return an earlier time on consecutive calls to the
    // performance counter.
    // Let's store the previous time to ensure we don't
    // time travel in some way, since the measured times
    // are defined as being monotonic (non-decreasing).
    static sf::Int64 previous = 0;

    // Get the current time
    LARGE_INTEGER time;
    QueryPerformanceCounter(&time);
    sf::Int64 now = 1000000 * time.QuadPart / frequency.QuadPart;

    if (now < previous) // Did we time travel?
        now = previous; // If so, let's go back to the future.
    else
        previous = now; // Otherwise, store this time.

    // Return the current time as microseconds
    return sf::microseconds(now);
}

} // namespace priv

} // namespace sf
