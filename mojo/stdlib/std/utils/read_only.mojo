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
"""Implements the Readonly datatype and readonly function."""

from memory import OwnedPointer
from builtin.constrained import _constrained_conforms_to
from builtin.rebind import trait_downcast, downcast


struct Readonly[T: Movable](Copyable, ImplicitlyDestructible):
    """A wrapper type to provide a runtime read-only value.

    `Readonly` wraps a value that is initialized at runtime and can't be
    modified thereafter. It provides a read-only reference to the underlying
    value. It is guaranteed that no mutable aliases to the underlying value
    exist after construction.

    Example:
    ```mojo
    from time import perf_counter_ns
    from utils import Readonly

    def main():
        ref start_time = Readonly(perf_counter_ns())[]
        # value is known at runtime but must stay immutable thereafter
        # ... any code here is guaranteed to not modify start_time ...
        # start_time = 0  # compile-time error
        var duration = perf_counter_ns() - start_time
        print("Duration (ns): ", duration)
    ```

    Prefer using the `readonly` function if only a read-only reference to
    a value is needed without guarantees about the absence of other mutable
    aliases.

    Prefer `comptime` for constant values that are known at compile time:

    ```mojo
    def main():
        comptime magic_number = 42
        # value is known at compilation time
        # ... any code here is guaranteed to not modify magic_number ...
        print("Magic Number: ", magic_number)
    ```

    Parameters:
        T: The type of the value being wrapped. Must be `Movable`.
    """

    var _value: UnsafePointer[Self.T, MutExternalOrigin]
    """The underlying value. Never access directly."""

    @always_inline
    fn __init__(out self, var value: Self.T):
        """Initializes a `Readonly` instance with the provided value.

        Args:
            value: The value to be wrapped as read-only.

        Returns:
            A new `Readonly` instance wrapping the provided value.
        """
        self._value = alloc[Self.T](1)
        self._value.init_pointee_move(value^)

    fn __copyinit__(out self, other: Self):
        """Initializes a `Readonly` instance by copying from another instance.

        Args:
            other: The `Readonly` instance to copy from.

        Returns:
            A new `Readonly` instance that is a copy of the provided instance.
        """
        _constrained_conforms_to[
            conforms_to(Self.T, Copyable),
            Parent=Self,
            Element = Self.T,
            ParentConformsTo="Copyable",
        ]()
        comptime TCopyable = downcast[Self.T, Copyable]
        self._value = alloc[Self.T](1)
        self._value.bitcast[TCopyable]().init_pointee_copy(
            rebind[UnsafePointer[TCopyable, MutExternalOrigin]](other._value)[]
        )

    fn __del__(deinit self):
        """Destroy the Readonly instance and its underlying value."""
        _constrained_conforms_to[
            conforms_to(Self.T, ImplicitlyDestructible),
            Parent=Self,
            Element = Self.T,
            ParentConformsTo="ImplicitlyDestructible",
        ]()
        comptime TDestructible = downcast[Self.T, ImplicitlyDestructible]
        self._value.bitcast[TDestructible]().destroy_pointee()
        self._value.free()

    @always_inline
    fn __getitem__(self) -> ref [self] Self.T:
        """Get the underlying value as a read-only reference.

        Returns:
            A read-only reference to the underlying value.
        """
        return self._value[]

    fn destroy_with(deinit self, destroy_fn: fn (var Self.T)):
        """Destroy the Readonly instance using a custom destructor.

        Args:
            destroy_fn: A function that takes a reference to the
                    underlying value and performs custom destruction logic.
        """
        self._value.destroy_pointee_with(destroy_fn)
        self._value.free()


fn readonly[o: ImmutOrigin, T: AnyType](ref [o]value: T) -> ref [o] T:
    """Returns a read-only reference to the provided value.

    This does not move or copy a value as the`Readonly` type does.
    In contrast to using the `Readonly` type, other mutable value bindings
    to the same value might exist.

    Prefer `comptime` for constant values that are known at compile time.

    this function might not be needed if the current value binding is already
    a read-only (`read`) reference.

    Args:
        value: The value to return a read-only reference for.

    Returns:
        A read-only reference to the provided value.
    """
    return value
