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
# RUN: not %mojo -D my_false=blah %s 2>&1 | FileCheck %s -check-prefix=CHECK-FAIL

from sys import env_get_bool


# CHECK-FAIL: constraint failed: the boolean environment value of `my_false` with value `blah` is not recognized
fn main():
    _ = env_get_bool["my_false"]()
