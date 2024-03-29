#pragma once

/*!
 * \file widget.hpp
 * \brief Contains declarations related to Widget objects to be manufactured
 *
 * This is a more detailed explanation of this file, but it's truly simple
 */

#include <libsingle/export_macros.hpp>
#include <string>

namespace single {

/*!
 * \brief Forward declaration for friendship relationship
 */
class LIBSINGLE_EXPORT Factory;

/*!
 * \brief Represents the Widgets being manufactured.
 *
 * In detail, widgets are the best
 */
class LIBSINGLE_EXPORT Widget {
private:
  int value{0};

  /*
   * Widget constructor with specified value. Widgets must be created through a
   * Factory.
   */
  explicit Widget(int value);

  friend Factory;  //!< Factory has special privilege

public:
  Widget() = delete;

  /*!
   * Simply returns the internal Widget#value
   */
  [[nodiscard]] constexpr int get_value() const noexcept { return this->value; }

  /*!
   * Builds the production stamp associated with this Widget
   */
  [[nodiscard]] std::string get_stamp() const;
};

}  // namespace single
