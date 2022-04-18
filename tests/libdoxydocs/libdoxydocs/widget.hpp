#pragma once

/*!
 * \file widget.hpp
 * \brief Contains declarations related to Widget objects to be manufactured
 *
 * This is a more detailed explanation of this file, but it's truly simple
 */

#include <libdoxydocs/export_macros.hpp>

namespace doxydocs {

/*!
 * \brief Forward declaration for friendship relationship
 */
class LIBDOXYDOCS_EXPORT Factory;

/*!
 * \brief Represents the Widgets being manufactured.
 *
 * In detail, widgets are the best
 */
class Widget {
 private:
  int value{0};

  /*
   * Widget constructor with specified value. Widgets must be created through a
   * Factory.
   */
  explicit Widget(const int value);

  friend Factory;  //!< Factory has special privilege

 public:
  Widget() = delete;

  /*!
   * Simply returns the internal Widget#value
   */
  constexpr int get_value() const noexcept { return this->value; }
};

}  // namespace doxydocs
