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

from testing import TestSuite, assert_equal
from test_utils import ExplicitDelOnly, MoveOnly
from utils import Readonly, readonly


fn get_runtime_value() -> String:
    """Simulate a function that returns a runtime value."""
    return "user input"


def test_readonly_type_default_usage():
    ref ro_ref = Readonly(get_runtime_value())[]
    # ro_ref = ""  # compile-time error

    assert_equal(
        ro_ref,
        "user input",
        msg="failed to use runtime read-only ro_ref",
    )


def test_readonly_type_movable():
    var ro_val = Readonly("Hallo")
    var ro_val_moved = ro_val^

    assert_equal(
        ro_val_moved[],
        "Hallo",
        msg="failed to use compile-time read-only ro_val",
    )


def test_readonly_type_immutable():
    var runtime_value = get_runtime_value()
    ref ro_ref = Readonly(runtime_value)[]
    runtime_value = ""  # does not affect ro_ref
    # ro_ref = ""  # compile-time error

    assert_equal(
        ro_ref,
        "user input",
        msg="failed to use runtime read-only ro_ref",
    )
    assert_equal(
        runtime_value,
        "",
    )


def test_readonly_type_MoveOnly():
    var ro_val = Readonly(MoveOnly(get_runtime_value()))
    var ro_val_moved = ro_val^

    assert_equal(
        ro_val_moved[].data,
        "user input",
        msg="failed to use runtime read-only ro_ref",
    )


def test_readonly_type_copy():
    var ro_val = Readonly("Hallo")
    var ro_val_copy = ro_val.copy()  # test Copyable conformance
    assert_equal(ro_val_copy[], "Hallo", msg="failed to copy Readonly value")


def test_readonly_type_in_list():
    var list_with_ro = [Readonly(1), Readonly(2), Readonly(3)]
    list_with_ro.append(Readonly(4))  # OK Append a readonly value to the list
    list_with_ro[2] = Readonly(10)  # OK Replace a readonly value in the list
    # list_with_ro[2] += 1 # compile-time error

    list_with_ro_2 = list_with_ro.copy()
    assert_equal(
        len(list_with_ro_2),
        4,
        msg="failed to use runtime read-only ro_ref for list",
    )


def test_readonly_type_explicit_del():
    var runtime_value = Readonly(ExplicitDelOnly(1))
    ref ro_ref = runtime_value[]

    try:
        assert_equal(
            ro_ref.data,
            1,
            msg="failed to use runtime read-only ro_ref for @explicit_del type",
        )
    finally:
        runtime_value^.destroy_with(ExplicitDelOnly.destroy)


def test_readonly_function():
    ref ro_ref = readonly(get_runtime_value())
    # ro_ref = ""  # compile-time error
    assert_equal(
        ro_ref,
        "user input",
        msg="failed to use runtime read-only ro_ref from readonly function",
    )


def main():
    TestSuite.discover_tests[__functions_in_module()]().run()
