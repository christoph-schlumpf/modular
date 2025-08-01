# ===----------------------------------------------------------------------=== #
# Copyright (c) 2025, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
"""Implements various testing utils.

You can import these APIs from the `testing` package. For example:

```mojo
from testing import assert_true

def main():
    x = 1
    y = 2
    try:
        assert_true(x==1)
        assert_true(y==2)
        assert_true((x+y)==3)
        print("All assertions succeeded")
    except e:
        print("At least one assertion failed:")
        print(e)
```
"""

from math import isclose

from builtin._location import __call_location, _SourceLocation
from memory import memcmp
from python import PythonObject

# ===----------------------------------------------------------------------=== #
# Assertions
# ===----------------------------------------------------------------------=== #


@always_inline
fn _assert_error[T: Writable](msg: T, loc: _SourceLocation) -> String:
    return loc.prefix(String("AssertionError: ", msg))


@always_inline
fn assert_true[
    T: Boolable, //
](
    val: T,
    msg: String = "condition was unexpectedly False",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input value is True and raises an Error if it's not.

    Parameters:
        T: The type of the value argument.

    Args:
        val: The value to assert to be True.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if not val:
        raise _assert_error(msg, location.or_else(__call_location()))


@always_inline
fn assert_false[
    T: Boolable, //
](
    val: T,
    msg: String = "condition was unexpectedly True",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input value is False and raises an Error if it's not.

    Parameters:
        T: The type of the value argument.

    Args:
        val: The value to assert to be False.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if val:
        raise _assert_error(msg, location.or_else(__call_location()))


@always_inline
fn assert_equal[
    T: EqualityComparable & Stringable, //
](
    lhs: T,
    rhs: T,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values are equal. If it is not then an Error
    is raised.

    Parameters:
        T: The type of the input values.

    Args:
        lhs: The lhs of the equality.
        rhs: The rhs of the equality.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs != rhs:
        raise _assert_cmp_error["`left == right` comparison"](
            String(lhs),
            String(rhs),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


# TODO: Remove the PythonObject, String, SIMD and List overloads once we have
# more powerful traits.
@always_inline
fn assert_equal(
    lhs: String,
    rhs: String,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values are equal. If it is not then an Error
    is raised.

    Args:
        lhs: The lhs of the equality.
        rhs: The rhs of the equality.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs != rhs:
        raise _assert_cmp_error["`left == right` comparison"](
            lhs, rhs, msg=msg, loc=location.or_else(__call_location())
        )


@always_inline
fn assert_equal[
    dtype: DType, size: Int
](
    lhs: SIMD[dtype, size],
    rhs: SIMD[dtype, size],
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values are equal. If it is not then an
    Error is raised.

    Parameters:
        dtype: The dtype of the left- and right-hand-side SIMD vectors.
        size: The width of the left- and right-hand-side SIMD vectors.

    Args:
        lhs: The lhs of the equality.
        rhs: The rhs of the equality.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if any(lhs != rhs):
        raise _assert_cmp_error["`left == right` comparison"](
            String(lhs),
            String(rhs),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_equal[
    T: Copyable & Movable & EqualityComparable & Representable, //
](
    lhs: List[T],
    rhs: List[T],
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that two lists are equal.

    Parameters:
        T: The type of the elements in the lists.

    Args:
        lhs: The left-hand side list.
        rhs: The right-hand side list.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs != rhs:
        raise _assert_cmp_error["`left == right` comparison"](
            lhs.__str__(),
            rhs.__str__(),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


# TODO(MSTDL-1071):
#   Once Mojo supports parametric traits, implement EqualityComparable for
#   StringSlice such that string slices with different origin types can be
#   compared, then drop this overload.
@always_inline
fn assert_equal[
    O1: ImmutableOrigin,
    O2: ImmutableOrigin,
](
    lhs: List[StringSlice[O1]],
    rhs: List[StringSlice[O2]],
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that two lists are equal.

    Parameters:
        O1: The origin of lhs.
        O2: The origin of rhs.

    Args:
        lhs: The left-hand side list.
        rhs: The right-hand side list.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """

    # Cast `rhs` to have the same origin as `lhs`, so that we can delegate to
    # `List.__ne__`.
    var rhs_origin_casted = rebind[List[StringSlice[O1]]](rhs)

    if lhs != rhs_origin_casted:
        raise _assert_cmp_error["`left == right` comparison"](
            lhs.__str__(),
            rhs.__str__(),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_equal[
    O: ImmutableOrigin,
](
    lhs: StringSlice[O],
    rhs: String,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that a `StringSlice` is equal to a `String`."""
    if lhs != rhs:
        raise _assert_cmp_error["`left == right` comparison"](
            lhs.__str__(),
            rhs,
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_equal[
    O: ImmutableOrigin,
](
    lhs: String,
    rhs: StringSlice[O],
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that a `String` is equal to a `StringSlice`."""
    if lhs != rhs:
        raise _assert_cmp_error["`left == right` comparison"](
            lhs,
            rhs.__str__(),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_equal[
    dtype: DType
](
    lhs: List[Scalar[dtype]],
    rhs: List[Scalar[dtype]],
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that two lists are equal.

    Parameters:
        dtype: A DType.

    Args:
        lhs: The left-hand side list.
        rhs: The right-hand side list.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    var length = len(lhs)
    if (
        length != len(rhs)
        or memcmp(lhs.unsafe_ptr(), rhs.unsafe_ptr(), length) != 0
    ):
        raise _assert_cmp_error["`left == right` comparison"](
            lhs.__str__(),
            rhs.__str__(),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_equal_pyobj(
    lhs: PythonObject,
    rhs: PythonObject,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the `PythonObject`s are equal. If it is not then an Error
    is raised.

    Args:
        lhs: The lhs of the equality.
        rhs: The rhs of the equality.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (default to the `__call_location`).

    Raises:
        An Error with the provided message if assert fails.
    """
    if lhs != rhs:
        raise _assert_cmp_error["`left == right` comparison"](
            String(lhs),
            String(rhs),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_not_equal[
    T: EqualityComparable & Stringable, //
](
    lhs: T,
    rhs: T,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values are not equal. If it is not then an
    Error is raised.

    Parameters:
        T: The type of the input values.

    Args:
        lhs: The lhs of the inequality.
        rhs: The rhs of the inequality.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs == rhs:
        raise _assert_cmp_error["`left != right` comparison"](
            String(lhs),
            String(rhs),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_not_equal(
    lhs: String,
    rhs: String,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values are not equal. If it is not then an
    an Error is raised.

    Args:
        lhs: The lhs of the inequality.
        rhs: The rhs of the inequality.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs == rhs:
        raise _assert_cmp_error["`left != right` comparison"](
            lhs, rhs, msg=msg, loc=location.or_else(__call_location())
        )


@always_inline
fn assert_not_equal[
    dtype: DType, size: Int
](
    lhs: SIMD[dtype, size],
    rhs: SIMD[dtype, size],
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values are not equal. If it is not then an
    Error is raised.

    Parameters:
        dtype: The dtype of the left- and right-hand-side SIMD vectors.
        size: The width of the left- and right-hand-side SIMD vectors.

    Args:
        lhs: The lhs of the inequality.
        rhs: The rhs of the inequality.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if all(lhs == rhs):
        raise _assert_cmp_error["`left != right` comparison"](
            String(lhs),
            String(rhs),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_not_equal[
    T: Copyable & Movable & EqualityComparable & Representable, //
](
    lhs: List[T],
    rhs: List[T],
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that two lists are not equal.

    Parameters:
        T: The type of the elements in the lists.

    Args:
        lhs: The left-hand side list.
        rhs: The right-hand side list.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs == rhs:
        raise _assert_cmp_error["`left != right` comparison"](
            lhs.__str__(),
            rhs.__str__(),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_almost_equal[
    dtype: DType, size: Int
](
    lhs: SIMD[dtype, size],
    rhs: SIMD[dtype, size],
    msg: String = "",
    *,
    atol: Float64 = 1e-08,
    rtol: Float64 = 1e-05,
    equal_nan: Bool = False,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values are equal up to a tolerance. If it is
    not then an Error is raised.

    When the type is boolean or integral, then equality is checked. When the
    type is floating-point, then this checks if the two input values are
    numerically the close using the $abs(lhs - rhs) <= max(rtol * max(abs(lhs),
    abs(rhs)), atol)$ formula.

    Constraints:
        The type must be boolean, integral, or floating-point.

    Parameters:
        dtype: The dtype of the left- and right-hand-side SIMD vectors.
        size: The width of the left- and right-hand-side SIMD vectors.

    Args:
        lhs: The lhs of the equality.
        rhs: The rhs of the equality.
        msg: The message to print.
        atol: The absolute tolerance.
        rtol: The relative tolerance.
        equal_nan: Whether to treat nans as equal.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    constrained[
        dtype is DType.bool or dtype.is_integral() or dtype.is_floating_point(),
        "type must be boolean, integral, or floating-point",
    ]()

    var almost_equal = isclose(
        lhs, rhs, atol=atol, rtol=rtol, equal_nan=equal_nan
    )

    if not all(almost_equal):
        var err = String(lhs, " is not close to ", rhs)

        @parameter
        if dtype.is_integral() or dtype.is_floating_point():
            err += String(" with a diff of ", abs(lhs - rhs))

        if msg:
            err += String(" (", msg, ")")

        raise _assert_error(err, location.or_else(__call_location()))


@always_inline
fn assert_is[
    T: Stringable & Identifiable
](
    lhs: T,
    rhs: T,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values have the same identity. If they do not
    then an Error is raised.

    Parameters:
        T: A Stringable and Identifiable type.

    Args:
        lhs: The lhs of the `is` statement.
        rhs: The rhs of the `is` statement.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs is not rhs:
        raise _assert_cmp_error["`left is right` identification"](
            String(lhs),
            String(rhs),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


@always_inline
fn assert_is_not[
    T: Stringable & Identifiable
](
    lhs: T,
    rhs: T,
    msg: String = "",
    *,
    location: Optional[_SourceLocation] = None,
) raises:
    """Asserts that the input values have different identities. If they do not
    then an Error is raised.

    Parameters:
        T: A Stringable and Identifiable type.

    Args:
        lhs: The lhs of the `is not` statement.
        rhs: The rhs of the `is not` statement.
        msg: The message to be printed if the assertion fails.
        location: The location of the error (defaults to `__call_location`).

    Raises:
        An Error with the provided message if assert fails and `None` otherwise.
    """
    if lhs is rhs:
        raise _assert_cmp_error["`left is not right` identification"](
            String(lhs),
            String(rhs),
            msg=msg,
            loc=location.or_else(__call_location()),
        )


fn _assert_cmp_error[
    cmp: String
](lhs: String, rhs: String, *, msg: String, loc: _SourceLocation) -> String:
    var err = cmp + " failed:\n   left: " + lhs + "\n  right: " + rhs
    if msg:
        err += "\n  reason: " + msg
    return _assert_error(err, loc)


struct assert_raises:
    """Context manager that asserts that the block raises an exception.

    You can use this to test expected error cases, and to test that the correct
    errors are raised. For instance:

    ```mojo
    from testing import assert_raises

    # Good! Caught the raised error, test passes
    with assert_raises():
        raise Error("SomeError")

    # Also good!
    with assert_raises(contains="Some"):
        raise Error("SomeError")

    # This will assert, we didn't raise
    with assert_raises():
        pass

    # This will let the underlying error propagate, failing the test
    with assert_raises(contains="Some"):
        raise Error("OtherError")
    ```
    """

    var message_contains: Optional[String]
    """If present, check that the error message contains this literal string."""

    var call_location: _SourceLocation
    """Assigned the value returned by __call_locations() at Self.__init__."""

    @always_inline
    fn __init__(out self, *, location: Optional[_SourceLocation] = None):
        """Construct a context manager with no message pattern.

        Args:
            location: The location of the error (defaults to `__call_location`).
        """
        self.message_contains = None
        self.call_location = location.or_else(__call_location())

    @always_inline
    fn __init__(
        out self,
        *,
        contains: String,
        location: Optional[_SourceLocation] = None,
    ):
        """Construct a context manager matching specific errors.

        Args:
            contains: The test will only pass if the error message
                includes the literal text passed.
            location: The location of the error (defaults to `__call_location`).
        """
        self.message_contains = contains
        self.call_location = location.or_else(__call_location())

    fn __enter__(self):
        """Enter the context manager."""
        pass

    fn __exit__(self) raises:
        """Exit the context manager with no error.

        Raises:
            AssertionError: Always. The block must raise to pass the test.
        """
        raise Error("AssertionError: Didn't raise at ", self.call_location)

    fn __exit__(self, error: Error) raises -> Bool:
        """Exit the context manager with an error.

        Args:
            error: The error raised.

        Raises:
            Error: If the error raised doesn't include the expected string.

        Returns:
            True if the error message contained the expected string.
        """
        if self.message_contains:
            return self.message_contains.value() in String(error)
        return True
