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

from collections import Set

from testing import assert_equal as AE
from testing import assert_false, assert_raises, assert_true


fn assert_equal[T: EqualityComparable](lhs: T, rhs: T) raises:
    if not lhs == rhs:
        raise Error("AssertionError: values not equal, can't stringify :(")


def test_set_construction():
    # Constructors.
    _ = Set[Int]()
    _ = Set[String]()
    _ = Set[Int](1, 2, 3)
    _ = Set(Set[Int](1, 2, 3))

    # Literals.
    var s1 = {1, 2, 3}
    assert_equal(s1, {1, 2, 3})

    var s2 = {"1", "2"}
    assert_equal(s2, {"1", "2"})


def test_set_move():
    var s1 = {1, 2, 3}
    var s2 = s1^
    assert_equal(s2, {1, 2, 3})


def test_set_copy():
    var s1 = {1, 2, 3}
    var s2 = s1
    assert_equal(s1, s2)


def test_len():
    var s1 = Set[Int]()
    assert_equal(0, len(s1))

    var s2 = {1, 2, 3}
    assert_equal(3, len(s2))


def test_in():
    var s1 = Set[Int]()
    assert_false(0 in s1)
    assert_false(1 in s1)

    var s2 = {1, 2, 3}
    assert_false(0 in s2)
    assert_true(1 in s2)
    assert_true(2 in s2)
    assert_true(3 in s2)
    assert_false(4 in s2)


def test_equal():
    var s1 = Set[Int]()
    var s2 = {1, 2, 3}

    # TODO(#33178): Not using `assert_equal` and friends
    # since Set is not Stringable

    assert_true(s1 == s1)
    assert_true(s2 == s2)
    assert_true(s1 == {})
    assert_true(s2 == {3, 2, 1})
    assert_true(s1 != s2)
    assert_true(s2 != s1)
    assert_true(s2 != {1, 2, 2})
    assert_true(s2 != {1, 2, 4})


def test_bool():
    assert_false(Set[Int]())
    assert_false(Set[Int](List[Int]()))
    assert_true(Set[Int](1))
    assert_true(Set[Int](1, 2, 3))


def test_intersection():
    assert_equal(Set[Int]() & {}, {})
    assert_equal(Set[Int]() & {1, 2, 3}, {})
    assert_equal({1, 2, 3} & {1, 2, 3}, {1, 2, 3})
    assert_equal({1, 2, 3} & {}, {})
    assert_equal({1, 2, 3} & {3, 4}, {3})

    assert_equal(Set[Int]().intersection({}), {})
    assert_equal(Set[Int]().intersection({1, 2, 3}), {})
    assert_equal({1, 2, 3}.intersection({1, 2, 3}), {1, 2, 3})
    assert_equal({1, 2, 3}.intersection({}), {})
    assert_equal({1, 2, 3}.intersection({3, 4}), {3})

    var x = Set[Int]()
    x &= {1, 2, 3}
    assert_equal(x, {})

    x = Set[Int]()
    x &= {}
    assert_equal(x, {})

    x = {1, 2, 3}
    x &= {}
    assert_equal(x, {})

    x = {1, 2, 3}
    x &= {1, 2, 3}
    assert_equal(x, {1, 2, 3})

    x = {1, 2}
    x &= {2, 3}
    assert_equal(x, {2})


def test_union():
    assert_equal(Set[Int]() | {}, {})
    assert_equal(Set[Int]() | {1, 2, 3}, {1, 2, 3})
    assert_equal({1, 2, 3} | {1, 2, 3}, {1, 2, 3})
    assert_equal({1, 2, 3} | {}, {1, 2, 3})
    assert_equal({1, 2, 3} | {3, 4}, {1, 2, 3, 4})

    assert_equal(Set[Int]().union({}), {})
    assert_equal(Set[Int]().union({1, 2, 3}), {1, 2, 3})
    assert_equal({1, 2, 3}.union({1, 2, 3}), {1, 2, 3})
    assert_equal({1, 2, 3}.union({}), {1, 2, 3})
    assert_equal({1, 2, 3}.union({3, 4}), {1, 2, 3, 4})

    var x = Set[Int]()
    x |= {1, 2, 3}
    assert_equal(x, {1, 2, 3})

    x = Set[Int]()
    x |= {}
    assert_equal(x, {})

    x = {1, 2, 3}
    x |= {}
    assert_equal(x, {1, 2, 3})

    x = {1, 2, 3}
    x |= {1, 2, 3}
    assert_equal(x, {1, 2, 3})

    x = {1, 2}
    x |= {2, 3}
    assert_equal(x, {1, 2, 3})


def test_subtract():
    var s1 = Set[Int]()
    var s2 = {1, 2, 3}

    assert_equal(s1 - s1, s1)
    assert_equal(s1 - s2, s1)
    assert_equal(s2 - s2, s1)
    assert_equal(s2 - s1, s2)
    assert_equal(s2 - {3, 4}, {1, 2})


def test_difference_update():
    var x = Set[Int]()
    x.difference_update({})
    assert_equal(x, {})

    x = {1, 2, 3}
    x.difference_update({1, 2, 3})
    assert_equal(x, {})

    x = {1, 2, 3}
    x.difference_update({})
    assert_equal(x, {1, 2, 3})

    x = {1, 2, 3}
    x.difference_update({3, 4})
    assert_equal(x, {1, 2})

    x = Set[Int]()
    x -= {}
    assert_equal(x, {})

    x = {1, 2, 3}
    x -= {1, 2, 3}
    assert_equal(x, {})

    x = {1, 2, 3}
    x -= {}
    assert_equal(x, {1, 2, 3})

    x = {1, 2, 3}
    x -= {3, 4}
    assert_equal(x, {1, 2})


def test_iter():
    var sum = 0
    for e in Set[Int]():
        sum += e

    assert_equal(sum, 0)

    sum = 0
    for e in {1, 2, 3}:
        sum += e

    assert_equal(sum, 6)


def test_add():
    var s = Set[Int]()
    s.add(1)
    assert_equal(s, {1})

    s.add(2)
    assert_equal(s, {1, 2})

    s.add(3)
    assert_equal(s, {1, 2, 3})

    # 1 is already in the set
    s.add(1)
    assert_equal(s, {1, 2, 3})


def test_remove():
    var s = {1, 2, 3}
    s.remove(1)
    assert_equal(s, {2, 3})

    s.remove(2)
    assert_equal(s, {3})

    s.remove(3)
    assert_equal(s, {})

    with assert_raises():
        # 1 not in the set, should raise
        s.remove(1)


def test_pop_insertion_order():
    var s = {1, 2, 3}
    assert_equal(s.pop(), 1)
    assert_equal(s, {2, 3})

    s.add(4)

    assert_equal(s.pop(), 2)
    assert_equal(s, {3, 4})

    assert_equal(s.pop(), 3)
    assert_equal(s, {4})

    assert_equal(s.pop(), 4)
    assert_equal(s, {})

    with assert_raises():
        _ = s.pop()  # pop from empty set raises


def test_issubset():
    assert_true(Set[Int]().issubset({1, 2, 3}))
    assert_true(Set[Int]() <= {1, 2, 3})

    assert_true({1, 2, 3}.issubset({1, 2, 3}))
    assert_true({1, 2, 3} <= {1, 2, 3})

    assert_true({2, 3}.issubset({1, 2, 3, 4}))
    assert_true({2, 3} <= {1, 2, 3, 4})

    assert_false({1, 2, 3, 4}.issubset({2, 3}))
    assert_false({1, 2, 3, 4} <= {2, 3})

    assert_false({1, 2, 3, 4, 5}.issubset({2, 3}))
    assert_false({1, 2, 3, 4, 5} <= {2, 3})

    assert_true(Set[Int]().issubset({}))
    assert_true(Set[Int]() <= {})

    assert_false({1, 2, 3}.issubset({4, 5, 6}))
    assert_false({1, 2, 3} <= {4, 5, 6})


def test_disjoint():
    assert_true(Set[Int]().isdisjoint({}))
    assert_false({1, 2, 3}.isdisjoint({1, 2, 3}))
    assert_true({1, 2, 3}.isdisjoint({4, 5, 6}))
    assert_false({1, 2, 3}.isdisjoint({3, 4, 5}))
    assert_true(Set[Int]().isdisjoint({1, 2, 3}))
    assert_true({1, 2, 3}.isdisjoint({}))
    assert_false({1, 2, 3}.isdisjoint({3}))
    assert_true({1, 2, 3}.isdisjoint({4}))


def test_issuperset():
    assert_true({1, 2, 3}.issuperset({}))
    assert_true({1, 2, 3} >= {})

    assert_true({1, 2, 3}.issuperset({1, 2, 3}))
    assert_true({1, 2, 3} >= {1, 2, 3})

    assert_true({1, 2, 3, 4}.issuperset({2, 3}))
    assert_true({1, 2, 3, 4} >= {2, 3})

    assert_false({2, 3}.issuperset({1, 2, 3, 4}))
    assert_false({2, 3} >= {1, 2, 3, 4})

    assert_false({1, 2, 3}.issuperset({4, 5, 6}))
    assert_false({1, 2, 3} >= {4, 5, 6})

    assert_false(Set[Int]().issuperset({1, 2, 3}))
    assert_false(Set[Int]() >= {1, 2, 3})

    assert_false({1, 2, 3}.issuperset({1, 2, 3, 4}))
    assert_false({1, 2, 3} >= {1, 2, 3, 4})

    assert_true(Set[Int]().issuperset({}))
    assert_true(Set[Int]() >= {})


def test_greaterthan():
    assert_true({1, 2, 3, 4} > {2, 3})
    assert_false({2, 3} > {1, 2, 3, 4})
    assert_false({1, 2, 3} > {1, 2, 3})
    assert_false(Set[Int]() > {})
    assert_true({1, 2, 3} > {})


def test_lessthan():
    assert_true({2, 3} < {1, 2, 3, 4})
    assert_false({1, 2, 3, 4} < {2, 3})
    assert_false({1, 2, 3} < {1, 2, 3})
    assert_false(Set[Int]() < {})
    assert_true(Set[Int]() < {1, 2, 3})


def test_symmetric_difference():
    assert_true({1, 4} == {1, 2, 3}.symmetric_difference({2, 3, 4}))
    assert_true({1, 4} == {1, 2, 3} ^ {2, 3, 4})

    assert_true({1, 2, 3, 4, 5, 6} == {1, 2, 3}.symmetric_difference({4, 5, 6}))
    assert_true({1, 2, 3, 4, 5, 6} == {1, 2, 3} ^ {4, 5, 6})

    assert_true({1, 2, 3} == {1, 2, 3}.symmetric_difference({}))
    assert_true({1, 2, 3} == {1, 2, 3} ^ {})

    assert_true({1, 2, 3} == Set[Int]() ^ {1, 2, 3})
    assert_true({1, 2, 3} == Set[Int]() ^ {1, 2, 3})

    assert_true(Set[Int]() == Set[Int]().symmetric_difference({}))
    assert_true(Set[Int]() == Set[Int]() ^ {})

    assert_true(Set[Int]() == {1, 2, 3}.symmetric_difference({1, 2, 3}))
    assert_true(Set[Int]() == {1, 2, 3} ^ {1, 2, 3})


def test_symmetric_difference_update():
    # Test case 1
    set1 = {1, 2, 3}
    set2 = {2, 3, 4}
    set1.symmetric_difference_update(set2)
    assert_true({1, 4} == set1)

    set1 = {1, 2, 3}
    set2 = {2, 3, 4}
    set1 ^= set2
    assert_true({1, 4} == set1)

    # Test case 2
    set3 = {1, 2, 3}
    set4 = {4, 5, 6}
    set3.symmetric_difference_update(set4)
    assert_true({1, 2, 3, 4, 5, 6} == set3)

    set3 = {1, 2, 3}
    set4 = {4, 5, 6}
    set3 ^= set4
    assert_true({1, 2, 3, 4, 5, 6} == set3)

    # Test case 3
    set5 = {1, 2, 3}
    set6 = Set[Int]()
    set5.symmetric_difference_update(set6)
    assert_true({1, 2, 3} == set5)

    set5 = {1, 2, 3}
    set6 = Set[Int]()
    set5 ^= set6
    assert_true({1, 2, 3} == set5)

    # Test case 4
    set7 = Set[Int]()
    set8 = {1, 2, 3}
    set7.symmetric_difference_update(set8)
    assert_true({1, 2, 3} == set7)

    set7 = Set[Int]()
    set8 = {1, 2, 3}
    set7 ^= set8
    assert_true({1, 2, 3} == set7)

    # Test case 5
    set9 = Set[Int]()
    set10 = Set[Int]()
    set9.symmetric_difference_update(set10)
    assert_true(set9 == {})

    set9 = Set[Int]()
    set10 = Set[Int]()
    set9 ^= set10
    assert_true(set9 == {})

    # Test case 6
    set11 = {1, 2, 3}
    set12 = {1, 2, 3}
    set11.symmetric_difference_update(set12)
    assert_true(set11 == {})

    set11 = {1, 2, 3}
    set12 = {1, 2, 3}
    set11 ^= set12
    assert_true(set11 == {})


def test_discard():
    set1 = {1, 2, 3}
    set1.discard(2)
    assert_true(set1 == {1, 3})

    set2 = {1, 2, 3}
    set2.discard(4)
    assert_true(set2 == {1, 2, 3})

    set3 = Set[Int]()
    set3.discard(1)
    assert_true(set3 == {})

    set4 = {1, 2, 3, 4, 5}
    set4.discard(2)
    set4.discard(4)
    assert_true(set4 == {1, 3, 5})

    set5 = {1, 2, 3}
    set5.discard(1)
    set5.discard(2)
    set5.discard(3)
    assert_true(set5 == {})


def test_clear():
    # Shouldn't fail when clearing a 0 length set
    set0 = Set[Int]()
    set0.clear()
    assert_equal(0, len(set0))

    set1 = {1, 2, 3}
    set1.clear()
    assert_true(set1 == {})

    set2 = Set[Int]()
    set2.clear()
    assert_true(set2 == {})

    set3 = {1, 2, 3}
    set3.clear()
    set3.add(4)
    set3.add(5)
    assert_true(set3 == {4, 5})

    set4 = {1, 2, 3}
    set4.clear()
    set4.clear()
    set4.clear()
    assert_true(set4 == {})

    set5 = {1, 2, 3}
    set5.clear()
    assert_true(len(set5) == 0)


def test_set_str():
    var a = {1, 2, 3}
    AE(a.__str__(), "{1, 2, 3}")
    AE(a.__repr__(), "{1, 2, 3}")
    var b = {"a", "b"}
    AE(b.__str__(), "{'a', 'b'}")
    AE(Set[Int]().__str__(), "{}")


fn test[name: String, test_fn: fn () raises]() raises:
    print("Test", name, "...", end="")
    try:
        _ = test_fn()
    except e:
        print("FAIL")
        raise e
    print("PASS")


def test_set_comprehension():
    var s1 = {x * x for x in range(10) if x & 1}
    assert_equal(s1, {1, 9, 25, 49, 81})

    var s2 = {x * y for x in range(3) for y in s1}
    assert_equal(s2, {0, 0, 0, 0, 0, 1, 9, 25, 49, 81, 2, 18, 50, 98, 162})


def main():
    test["test_set_construction", test_set_construction]()
    test["test_set_move", test_set_move]()
    test_set_move()
    test["test_len", test_len]()
    test["test_in", test_in]()
    test["test_equal", test_equal]()
    test["test_bool", test_bool]()
    test["test_intersection", test_intersection]()
    test["test_union", test_union]()
    test["test_subtract", test_subtract]()
    test["test_difference_update", test_difference_update]()
    test["test_iter", test_iter]()
    test["test_add", test_add]()
    test["test_remove", test_remove]()
    test["test_pop_insertion_order", test_pop_insertion_order]()
    test["test_issubset", test_issubset]()
    test["test_disjoint", test_disjoint]()
    test["test_issuperset", test_issuperset]()
    test["test_greaterthan", test_greaterthan]()
    test["test_lessthan", test_lessthan]()
    test["test_symmetric_difference", test_symmetric_difference]()
    test["test_symmetric_difference_update", test_symmetric_difference_update]()
    test["test_discard", test_discard]()
    test["test_clear", test_clear]()
    test["test_set_str", test_set_str]()
    test["test_set_comprehension", test_set_comprehension]()
