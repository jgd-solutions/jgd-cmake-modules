#pragma once
/*!
 * \file factory.hpp
 * \brief Contains declarations related to the production of Widgets
 *
 * This is a more detailed explanation of this file, but it's truly simple
 */

#include <libsingle/widget.hpp>

namespace single {

/*!
 * \brief Uniformly produces Widgets based on a bunch of factors that couldn't
 * be put in a Widget constructor.
 *
 * In reality, there is also a physical factory. This abstraction helps to
 * properly represent reality.
 */
class Factory {
 private:
  int factory_num{0};  //!< Internal factory number

 public:
  /*!
   * Default constructor for the headquarters
   */
  Factory() = default;

  /*!
   * Constructs a Factory object representing the sister factories, with non-0
   * factory numbers.
   *
   * \param factory_num the factory number of the physical factory that this
   * Factory object represents
   */
  explicit Factory(const int factory_num);

  /*!
   * Manufactures Widgets from this Factory, with any scale.
   *
   * \param scale the scaling factor of the manufactured Widget
   * \return the manufactured Widget from this Factory and with the provided
   * scale
   */
  Widget manufacture(const int scale = 1) const noexcept;
};

}  // namespace single
