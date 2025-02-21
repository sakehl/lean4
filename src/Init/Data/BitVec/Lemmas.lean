/-
Copyright (c) 2023 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joe Hendrix, Harun Khan, Alex Keizer, Abdalrhman M Mohamed,

-/
prelude
import Init.Data.Bool
import Init.Data.BitVec.Basic
import Init.Data.Fin.Lemmas
import Init.Data.Nat.Lemmas
import Init.Data.Nat.Mod
import Init.Data.Int.Bitwise.Lemmas

set_option linter.missingDocs true

namespace BitVec

@[simp] theorem getLsbD_ofFin (x : Fin (2^n)) (i : Nat) :
    getLsbD (BitVec.ofFin x) i = x.val.testBit i := rfl

@[simp] theorem getLsbD_ge (x : BitVec w) (i : Nat) (ge : w ≤ i) : getLsbD x i = false := by
  let ⟨x, x_lt⟩ := x
  simp only [getLsbD_ofFin]
  apply Nat.testBit_lt_two_pow
  have p : 2^w ≤ 2^i := Nat.pow_le_pow_of_le_right (by omega) ge
  omega

@[simp] theorem getMsbD_ge (x : BitVec w) (i : Nat) (ge : w ≤ i) : getMsbD x i = false := by
  rw [getMsbD]
  simp only [Bool.and_eq_false_imp, decide_eq_true_eq]
  omega

theorem lt_of_getLsbD (x : BitVec w) (i : Nat) : getLsbD x i = true → i < w := by
  if h : i < w then
    simp [h]
  else
    simp [Nat.ge_of_not_lt h]

theorem lt_of_getMsbD (x : BitVec w) (i : Nat) : getMsbD x i = true → i < w := by
  if h : i < w then
    simp [h]
  else
    simp [Nat.ge_of_not_lt h]

@[simp] theorem getElem?_eq_getElem {l : BitVec w} {n} (h : n < w) : l[n]? = some l[n] := by
  simp only [getElem?_def, h, ↓reduceDIte]

theorem getElem?_eq_some {l : BitVec w} : l[n]? = some a ↔ ∃ h : n < w, l[n] = a := by
  simp only [getElem?_def]
  split
  · simp_all
  · simp; omega

@[simp] theorem getElem?_eq_none_iff {l : BitVec w} : l[n]? = none ↔ w ≤ n := by
  simp only [getElem?_def]
  split
  · simp_all
  · simp; omega

theorem getElem?_eq_none {l : BitVec w} (h : w ≤ n) : l[n]? = none := getElem?_eq_none_iff.mpr h

theorem getElem?_eq (l : BitVec w) (i : Nat) :
    l[i]? = if h : i < w then some l[i] else none := by
  split <;> simp_all

@[simp] theorem some_getElem_eq_getElem? (l : BitVec w) (i : Nat) (h : i < w) :
    (some l[i] = l[i]?) ↔ True := by
  simp [h]

@[simp] theorem getElem?_eq_some_getElem (l : BitVec w) (i : Nat) (h : i < w) :
    (l[i]? = some l[i]) ↔ True := by
  simp [h]

theorem getElem_eq_iff {l : BitVec w} {n : Nat} {h : n < w} : l[n] = x ↔ l[n]? = some x := by
  simp only [getElem?_eq_some]
  exact ⟨fun w => ⟨h, w⟩, fun h => h.2⟩

theorem getElem_eq_getElem? (l : BitVec w) (i : Nat) (h : i < w) :
    l[i] = l[i]?.get (by simp [getElem?_eq_getElem, h]) := by
  simp [getElem_eq_iff]

theorem getLsbD_eq_getElem?_getD {x : BitVec w} {i : Nat} :
    x.getLsbD i = x[i]?.getD false := by
  rw [getElem?_def]
  split
  · rfl
  · simp_all

/--
This normalized a bitvec using `ofFin` to `ofNat`.
-/
theorem ofFin_eq_ofNat : @BitVec.ofFin w (Fin.mk x lt) = BitVec.ofNat w x := by
  simp only [BitVec.ofNat, Fin.ofNat', lt, Nat.mod_eq_of_lt]

/-- Prove equality of bitvectors in terms of nat operations. -/
theorem eq_of_toNat_eq {n} : ∀ {x y : BitVec n}, x.toNat = y.toNat → x = y
  | ⟨_, _⟩, ⟨_, _⟩, rfl => rfl

@[simp] theorem val_toFin (x : BitVec w) : x.toFin.val = x.toNat := rfl

@[bv_toNat] theorem toNat_eq {x y : BitVec n} : x = y ↔ x.toNat = y.toNat :=
  Iff.intro (congrArg BitVec.toNat) eq_of_toNat_eq

@[bv_toNat] theorem toNat_ne {x y : BitVec n} : x ≠ y ↔ x.toNat ≠ y.toNat := by
  rw [Ne, toNat_eq]

theorem testBit_toNat (x : BitVec w) : x.toNat.testBit i = x.getLsbD i := rfl

theorem getMsb'_eq_getLsb' (x : BitVec w) (i : Fin w) :
    x.getMsb' i = x.getLsb' ⟨w - 1 - i, by omega⟩ := by
  simp only [getMsb', getLsb']

theorem getMsb?_eq_getLsb? (x : BitVec w) (i : Nat) :
    x.getMsb? i = if i < w then x.getLsb? (w - 1 - i) else none := by
  simp only [getMsb?, getLsb?_eq_getElem?]
  split <;> simp [getMsb'_eq_getLsb']

theorem getMsbD_eq_getLsbD (x : BitVec w) (i : Nat) : x.getMsbD i = (decide (i < w) && x.getLsbD (w - 1 - i)) := by
  rw [getMsbD, getLsbD]

theorem getLsbD_eq_getMsbD (x : BitVec w) (i : Nat) : x.getLsbD i = (decide (i < w) && x.getMsbD (w - 1 - i)) := by
  rw [getMsbD]
  by_cases h₁ : i < w <;> by_cases h₂ : w - 1 - i < w <;>
    simp only [h₁, h₂] <;> simp only [decide_True, decide_False, Bool.false_and, Bool.and_false, Bool.true_and, Bool.and_true]
  · congr
    omega
  all_goals
    apply getLsbD_ge
    omega

@[simp] theorem getLsb?_ge (x : BitVec w) (i : Nat) (ge : w ≤ i) : x[i]? = none := by
  simp [ge]

@[simp] theorem getMsb?_ge (x : BitVec w) (i : Nat) (ge : w ≤ i) : getMsb? x i = none := by
  simp [getMsb?_eq_getLsb?]; omega

theorem lt_of_getLsb?_eq_some (x : BitVec w) (i : Nat) : x[i]? = some b → i < w := by
  cases h : x[i]? with
  | none => simp
  | some => by_cases i < w <;> simp_all

theorem lt_of_getMsb?_eq_some (x : BitVec w) (i : Nat) : getMsb? x i = some b → i < w := by
  if h : i < w then
    simp [h]
  else
    simp [Nat.ge_of_not_lt h]

theorem lt_of_getLsb?_isSome (x : BitVec w) (i : Nat) : x[i]?.isSome → i < w := by
  cases h : x[i]? with
  | none => simp
  | some => by_cases i < w <;> simp_all

theorem lt_of_getMsb?_isSome (x : BitVec w) (i : Nat) : (getMsb? x i).isSome → i < w := by
  if h : i < w then
    simp [h]
  else
    simp [Nat.ge_of_not_lt h]

theorem getMsbD_eq_getMsb?_getD (x : BitVec w) (i : Nat) :
    x.getMsbD i = (x.getMsb? i).getD false := by
  rw [getMsbD_eq_getLsbD]
  by_cases h : w = 0
  · simp [getMsb?, h]
  · rw [getLsbD_eq_getElem?_getD, getMsb?_eq_getLsb?]
    split <;>
    · simp
      intros
      omega

-- We choose `eq_of_getLsbD_eq` as the `@[ext]` theorem for `BitVec`
-- somewhat arbitrarily over `eq_of_getMsbD_eq`.
@[ext] theorem eq_of_getLsbD_eq {x y : BitVec w}
    (pred : ∀(i : Fin w), x.getLsbD i.val = y.getLsbD i.val) : x = y := by
  apply eq_of_toNat_eq
  apply Nat.eq_of_testBit_eq
  intro i
  if i_lt : i < w then
    exact pred ⟨i, i_lt⟩
  else
    have p : i ≥ w := Nat.le_of_not_gt i_lt
    simp [testBit_toNat, getLsbD_ge _ _ p]

theorem eq_of_getMsbD_eq {x y : BitVec w}
    (pred : ∀(i : Fin w), x.getMsbD i.val = y.getMsbD i.val) : x = y := by
  simp only [getMsbD] at pred
  apply eq_of_getLsbD_eq
  intro ⟨i, i_lt⟩
  if w_zero : w = 0 then
    simp [w_zero]
  else
    have w_pos := Nat.pos_of_ne_zero w_zero
    have r : i ≤ w - 1 := by
      simp [Nat.le_sub_iff_add_le w_pos]
      exact i_lt
    have q_lt : w - 1 - i < w := by
      simp only [Nat.sub_sub]
      apply Nat.sub_lt w_pos
      simp [Nat.succ_add]
    have q := pred ⟨w - 1 - i, q_lt⟩
    simpa [q_lt, Nat.sub_sub_self, r] using q

-- This cannot be a `@[simp]` lemma, as it would be tried at every term.
theorem of_length_zero {x : BitVec 0} : x = 0#0 := by ext; simp

theorem toNat_zero_length (x : BitVec 0) : x.toNat = 0 := by simp [of_length_zero]
theorem getLsbD_zero_length (x : BitVec 0) : x.getLsbD i = false := by simp
theorem getMsbD_zero_length (x : BitVec 0) : x.getMsbD i = false := by simp
theorem msb_zero_length (x : BitVec 0) : x.msb = false := by simp [BitVec.msb, of_length_zero]

theorem toNat_of_zero_length (h : w = 0) (x : BitVec w) : x.toNat = 0 := by
  subst h; simp [toNat_zero_length]
theorem getLsbD_of_zero_length (h : w = 0) (x : BitVec w) : x.getLsbD i = false := by
  subst h; simp [getLsbD_zero_length]
theorem getMsbD_of_zero_length (h : w = 0) (x : BitVec w) : x.getMsbD i = false := by
  subst h; simp [getMsbD_zero_length]
theorem msb_of_zero_length (h : w = 0) (x : BitVec w) : x.msb = false := by
  subst h; simp [msb_zero_length]

theorem eq_of_toFin_eq : ∀ {x y : BitVec w}, x.toFin = y.toFin → x = y
  | ⟨_, _⟩, ⟨_, _⟩, rfl => rfl

@[simp] theorem toNat_ofBool (b : Bool) : (ofBool b).toNat = b.toNat := by
  cases b <;> rfl

@[simp] theorem msb_ofBool (b : Bool) : (ofBool b).msb = b := by
  cases b <;> simp [BitVec.msb, getMsbD, getLsbD]

theorem ofNat_one (n : Nat) : BitVec.ofNat 1 n = BitVec.ofBool (n % 2 = 1) :=  by
  rcases (Nat.mod_two_eq_zero_or_one n) with h | h <;> simp [h, BitVec.ofNat, Fin.ofNat']

theorem ofBool_eq_iff_eq : ∀ {b b' : Bool}, BitVec.ofBool b = BitVec.ofBool b' ↔ b = b' := by
  decide

@[simp] theorem not_ofBool : ~~~ (ofBool b) = ofBool (!b) := by cases b <;> rfl

@[simp, bv_toNat] theorem toNat_ofFin (x : Fin (2^n)) : (BitVec.ofFin x).toNat = x.val := rfl

@[simp] theorem toNat_ofNatLt (x : Nat) (p : x < 2^w) : (x#'p).toNat = x := rfl

@[simp] theorem getLsbD_ofNatLt {n : Nat} (x : Nat) (lt : x < 2^n) (i : Nat) :
  getLsbD (x#'lt) i = x.testBit i := by
  simp [getLsbD, BitVec.ofNatLt]

@[simp, bv_toNat] theorem toNat_ofNat (x w : Nat) : (BitVec.ofNat w x).toNat = x % 2^w := by
  simp [BitVec.toNat, BitVec.ofNat, Fin.ofNat']

@[simp] theorem toFin_ofNat (x : Nat) : toFin (BitVec.ofNat w x) = Fin.ofNat' x (Nat.two_pow_pos w) := rfl

-- Remark: we don't use `[simp]` here because simproc` subsumes it for literals.
-- If `x` and `n` are not literals, applying this theorem eagerly may not be a good idea.
theorem getLsbD_ofNat (n : Nat) (x : Nat) (i : Nat) :
  getLsbD (BitVec.ofNat n x) i = (i < n && x.testBit i) := by
  simp [getLsbD, BitVec.ofNat, Fin.val_ofNat']

@[simp] theorem getLsbD_zero : (0#w).getLsbD i = false := by simp [getLsbD]

@[simp] theorem getMsbD_zero : (0#w).getMsbD i = false := by simp [getMsbD]

@[simp] theorem toNat_mod_cancel (x : BitVec n) : x.toNat % (2^n) = x.toNat :=
  Nat.mod_eq_of_lt x.isLt

@[simp] theorem sub_toNat_mod_cancel {x : BitVec w} (h : ¬ x = 0#w) :
    (2 ^ w - x.toNat) % 2 ^ w = 2 ^ w - x.toNat := by
  simp only [toNat_eq, toNat_ofNat, Nat.zero_mod] at h
  rw [Nat.mod_eq_of_lt (by omega)]

@[simp] theorem sub_sub_toNat_cancel {x : BitVec w} :
    2 ^ w - (2 ^ w - x.toNat) = x.toNat := by
  simp [Nat.sub_sub_eq_min, Nat.min_eq_right]
  omega

private theorem lt_two_pow_of_le {x m n : Nat} (lt : x < 2 ^ m) (le : m ≤ n) : x < 2 ^ n :=
  Nat.lt_of_lt_of_le lt (Nat.pow_le_pow_of_le_right (by trivial : 0 < 2) le)

@[simp]
theorem getLsbD_ofBool (b : Bool) (i : Nat) : (BitVec.ofBool b).getLsbD i = ((i = 0) && b) := by
  rcases b with rfl | rfl
  · simp [ofBool]
  · simp only [ofBool, ofNat_eq_ofNat, cond_true, getLsbD_ofNat, Bool.and_true]
    by_cases hi : i = 0 <;> simp [hi] <;> omega

/-! ### msb -/

@[simp] theorem msb_zero : (0#w).msb = false := by simp [BitVec.msb, getMsbD]

theorem msb_eq_getLsbD_last (x : BitVec w) :
    x.msb = x.getLsbD (w - 1) := by
  simp [BitVec.msb, getMsbD, getLsbD]
  rcases w  with rfl | w
  · simp [BitVec.eq_nil x]
  · simp

@[bv_toNat] theorem getLsbD_last (x : BitVec w) :
    x.getLsbD (w-1) = decide (2 ^ (w-1) ≤ x.toNat) := by
  rcases w with rfl | w
  · simp [toNat_of_zero_length]
  · simp only [getLsbD, Nat.testBit_to_div_mod, Nat.succ_sub_succ_eq_sub, Nat.sub_zero]
    rcases (Nat.lt_or_ge (BitVec.toNat x) (2 ^ w)) with h | h
    · simp [Nat.div_eq_of_lt h, h]
    · simp only [h]
      rw [Nat.div_eq_sub_div (Nat.two_pow_pos w) h, Nat.div_eq_of_lt]
      · decide
      · omega

@[bv_toNat] theorem getLsbD_succ_last (x : BitVec (w + 1)) :
    x.getLsbD w = decide (2 ^ w ≤ x.toNat) := getLsbD_last x

@[bv_toNat] theorem msb_eq_decide (x : BitVec w) : BitVec.msb x = decide (2 ^ (w-1) ≤ x.toNat) := by
  simp [msb_eq_getLsbD_last, getLsbD_last]

theorem toNat_ge_of_msb_true {x : BitVec n} (p : BitVec.msb x = true) : x.toNat ≥ 2^(n-1) := by
  match n with
  | 0 =>
    simp [BitVec.msb, BitVec.getMsbD] at p
  | n + 1 =>
    simp [BitVec.msb_eq_decide] at p
    simp only [Nat.add_sub_cancel]
    exact p

/-! ### cast -/

@[simp, bv_toNat] theorem toNat_cast (h : w = v) (x : BitVec w) : (cast h x).toNat = x.toNat := rfl
@[simp] theorem toFin_cast (h : w = v) (x : BitVec w) :
    (cast h x).toFin = x.toFin.cast (by rw [h]) :=
  rfl

@[simp] theorem getLsbD_cast (h : w = v) (x : BitVec w) : (cast h x).getLsbD i = x.getLsbD i := by
  subst h; simp

@[simp] theorem getMsbD_cast (h : w = v) (x : BitVec w) : (cast h x).getMsbD i = x.getMsbD i := by
  subst h; simp
@[simp] theorem msb_cast (h : w = v) (x : BitVec w) : (cast h x).msb = x.msb := by
  simp [BitVec.msb]

/-! ### toInt/ofInt -/

/-- Prove equality of bitvectors in terms of nat operations. -/
theorem toInt_eq_toNat_cond (x : BitVec n) :
    x.toInt =
      if 2*x.toNat < 2^n then
        (x.toNat : Int)
      else
        (x.toNat : Int) - (2^n : Nat) :=
  rfl

theorem msb_eq_false_iff_two_mul_lt {x : BitVec w} : x.msb = false ↔ 2 * x.toNat < 2^w := by
  cases w <;> simp [Nat.pow_succ, Nat.mul_comm _ 2, msb_eq_decide, toNat_of_zero_length]

theorem msb_eq_true_iff_two_mul_ge {x : BitVec w} : x.msb = true ↔ 2 * x.toNat ≥ 2^w := by
  simp [← Bool.ne_false_iff, msb_eq_false_iff_two_mul_lt]

/-- Characterize `x.toInt` in terms of `x.msb`. -/
theorem toInt_eq_msb_cond (x : BitVec w) :
    x.toInt = if x.msb then (x.toNat : Int) - (2^w : Nat) else (x.toNat : Int) := by
  simp only [BitVec.toInt, ← msb_eq_false_iff_two_mul_lt]
  cases x.msb <;> rfl


theorem toInt_eq_toNat_bmod (x : BitVec n) : x.toInt = Int.bmod x.toNat (2^n) := by
  simp only [toInt_eq_toNat_cond]
  split
  next g =>
    rw [Int.bmod_pos] <;> simp only [←Int.ofNat_emod, toNat_mod_cancel]
    omega
  next g =>
    rw [Int.bmod_neg] <;> simp only [←Int.ofNat_emod, toNat_mod_cancel]
    omega

/-- Prove equality of bitvectors in terms of nat operations. -/
theorem eq_of_toInt_eq {x y : BitVec n} : x.toInt = y.toInt → x = y := by
  intro eq
  simp [toInt_eq_toNat_cond] at eq
  apply eq_of_toNat_eq
  revert eq
  have _xlt := x.isLt
  have _ylt := y.isLt
  split <;> split <;> omega

theorem toInt_inj {x y : BitVec n} : x.toInt = y.toInt ↔ x = y :=
  Iff.intro eq_of_toInt_eq (congrArg BitVec.toInt)

theorem toInt_ne {x y : BitVec n} : x.toInt ≠ y.toInt ↔ x ≠ y  := by
  rw [Ne, toInt_inj]

@[simp] theorem toNat_ofInt {n : Nat} (i : Int) :
  (BitVec.ofInt n i).toNat = (i % (2^n : Nat)).toNat := by
  unfold BitVec.ofInt
  simp

theorem toInt_ofNat {n : Nat} (x : Nat) :
  (BitVec.ofNat n x).toInt = (x : Int).bmod (2^n) := by
  simp [toInt_eq_toNat_bmod]

@[simp] theorem toInt_ofInt {n : Nat} (i : Int) :
  (BitVec.ofInt n i).toInt = i.bmod (2^n) := by
  have _ := Nat.two_pow_pos n
  have p : 0 ≤ i % (2^n : Nat) := by omega
  simp [toInt_eq_toNat_bmod, Int.toNat_of_nonneg p]

@[simp] theorem ofInt_natCast (w n : Nat) :
  BitVec.ofInt w (n : Int) = BitVec.ofNat w n := rfl

@[simp] theorem ofInt_ofNat (w n : Nat) :
  BitVec.ofInt w (no_index (OfNat.ofNat n)) = BitVec.ofNat w (OfNat.ofNat n) := rfl

theorem toInt_neg_iff {w : Nat} {x : BitVec w} :
    BitVec.toInt x < 0 ↔ 2 ^ w ≤ 2 * x.toNat := by
  simp [toInt_eq_toNat_cond]; omega

theorem toInt_pos_iff {w : Nat} {x : BitVec w} :
    0 ≤ BitVec.toInt x ↔ 2 * x.toNat < 2 ^ w := by
  simp [toInt_eq_toNat_cond]; omega

/-! ### zeroExtend and truncate -/

theorem truncate_eq_zeroExtend {v : Nat} {x : BitVec w} :
  truncate v x = zeroExtend v x := rfl

@[simp, bv_toNat] theorem toNat_zeroExtend' {m n : Nat} (p : m ≤ n) (x : BitVec m) :
    (zeroExtend' p x).toNat = x.toNat := by
  simp [zeroExtend']

@[bv_toNat] theorem toNat_zeroExtend (i : Nat) (x : BitVec n) :
    BitVec.toNat (zeroExtend i x) = x.toNat % 2^i := by
  let ⟨x, lt_n⟩ := x
  simp only [zeroExtend]
  if n_le_i : n ≤ i then
    have x_lt_two_i : x < 2 ^ i := lt_two_pow_of_le lt_n n_le_i
    simp [n_le_i, Nat.mod_eq_of_lt, x_lt_two_i]
  else
    simp [n_le_i, toNat_ofNat]

theorem zeroExtend'_eq {x : BitVec w} (h : w ≤ v) : x.zeroExtend' h = x.zeroExtend v := by
  apply eq_of_toNat_eq
  rw [toNat_zeroExtend, toNat_zeroExtend']
  rw [Nat.mod_eq_of_lt]
  exact Nat.lt_of_lt_of_le x.isLt (Nat.pow_le_pow_right (Nat.zero_lt_two) h)

@[simp, bv_toNat] theorem toNat_truncate (x : BitVec n) : (truncate i x).toNat = x.toNat % 2^i :=
  toNat_zeroExtend i x

@[simp] theorem zeroExtend_eq (x : BitVec n) : zeroExtend n x = x := by
  apply eq_of_toNat_eq
  let ⟨x, lt_n⟩ := x
  simp [truncate, zeroExtend]

@[simp] theorem zeroExtend_zero (m n : Nat) : zeroExtend m 0#n = 0#m := by
  apply eq_of_toNat_eq
  simp [toNat_zeroExtend]

theorem truncate_eq (x : BitVec n) : truncate n x = x := zeroExtend_eq x

@[simp] theorem ofNat_toNat (m : Nat) (x : BitVec n) : BitVec.ofNat m x.toNat = truncate m x := by
  apply eq_of_toNat_eq
  simp

/-- Moves one-sided left toNat equality to BitVec equality. -/
theorem toNat_eq_nat {x : BitVec w} {y : Nat}
  : (x.toNat = y) ↔ (y < 2^w ∧ (x = BitVec.ofNat w y)) := by
  apply Iff.intro
  · intro eq
    simp [←eq, x.isLt]
  · intro eq
    simp [Nat.mod_eq_of_lt, eq]

/-- Moves one-sided right toNat equality to BitVec equality. -/
theorem nat_eq_toNat {x : BitVec w} {y : Nat}
  : (y = x.toNat) ↔ (y < 2^w ∧ (x = BitVec.ofNat w y)) := by
  rw [@eq_comm _ _ x.toNat]
  apply toNat_eq_nat

theorem getElem_zeroExtend' (x : BitVec w) (i : Nat) (h : w ≤ v) (hi : i < v) :
    (zeroExtend' h x)[i] = x.getLsbD i := by
  rw [getElem_eq_testBit_toNat, toNat_zeroExtend', getLsbD]

theorem getElem_zeroExtend (m : Nat) (x : BitVec n) (i : Nat) (h : i < m) :
    (zeroExtend m x)[i] = x.getLsbD i := by
  rw [zeroExtend]
  split
  · rw [getElem_zeroExtend']
  · simp [getElem_eq_testBit_toNat, getLsbD]
    omega

theorem getElem?_zeroExtend' (x : BitVec w) (i : Nat) (h : w ≤ v) :
    (zeroExtend' h x)[i]? = if i < v then some (x.getLsbD i) else none := by
  simp [getElem?_eq, getElem_zeroExtend']

theorem getElem?_zeroExtend (m : Nat) (x : BitVec n) (i : Nat) :
    (x.zeroExtend m)[i]? = if i < m then some (x.getLsbD i) else none := by
  simp [getElem?_eq, getElem_zeroExtend]

@[simp] theorem getLsbD_zeroExtend' (ge : m ≥ n) (x : BitVec n) (i : Nat) :
    getLsbD (zeroExtend' ge x) i = getLsbD x i := by
  simp [getLsbD, toNat_zeroExtend']

@[simp] theorem getMsbD_zeroExtend' (ge : m ≥ n) (x : BitVec n) (i : Nat) :
    getMsbD (zeroExtend' ge x) i = (decide (i ≥ m - n) && getMsbD x (i - (m - n))) := by
  simp only [getMsbD, getLsbD_zeroExtend', gt_iff_lt]
  by_cases h₁ : decide (i < m) <;> by_cases h₂ : decide (i ≥ m - n) <;> by_cases h₃ : decide (i - (m - n) < n) <;>
    by_cases h₄ : n - 1 - (i - (m - n)) = m - 1 - i
  all_goals
    simp only [h₁, h₂, h₃, h₄]
    simp_all only [ge_iff_le, decide_eq_true_eq, Nat.not_le, Nat.not_lt, Bool.true_and,
      Bool.false_and, Bool.and_self] <;>
    (try apply getLsbD_ge) <;>
    (try apply (getLsbD_ge _ _ _).symm) <;>
    omega

@[simp] theorem getLsbD_zeroExtend (m : Nat) (x : BitVec n) (i : Nat) :
    getLsbD (zeroExtend m x) i = (decide (i < m) && getLsbD x i) := by
  simp [getLsbD, toNat_zeroExtend, Nat.testBit_mod_two_pow]

@[simp] theorem getMsbD_zeroExtend_add {x : BitVec w} (h : k ≤ i) :
    (x.zeroExtend (w + k)).getMsbD i = x.getMsbD (i - k) := by
  by_cases h : w = 0
  · subst h; simp [of_length_zero]
  simp only [getMsbD, getLsbD_zeroExtend]
  by_cases h₁ : i < w + k <;> by_cases h₂ : i - k < w <;> by_cases h₃ : w + k - 1 - i < w + k
    <;> simp [h₁, h₂, h₃]
  · congr 1
    omega
  all_goals (first | apply getLsbD_ge | apply Eq.symm; apply getLsbD_ge)
    <;> omega

theorem getLsbD_truncate (m : Nat) (x : BitVec n) (i : Nat) :
    getLsbD (truncate m x) i = (decide (i < m) && getLsbD x i) :=
  getLsbD_zeroExtend m x i

theorem msb_truncate (x : BitVec w) : (x.truncate (k + 1)).msb = x.getLsbD k := by
  simp [BitVec.msb, getMsbD]

@[simp] theorem cast_zeroExtend (h : v = v') (x : BitVec w) :
    cast h (zeroExtend v x) = zeroExtend v' x := by
  subst h
  ext
  simp

@[simp] theorem cast_truncate (h : v = v') (x : BitVec w) :
    cast h (truncate v x) = truncate v' x := by
  subst h
  ext
  simp

@[simp] theorem zeroExtend_zeroExtend_of_le (x : BitVec w) (h : k ≤ l) :
    (x.zeroExtend l).zeroExtend k = x.zeroExtend k := by
  ext i
  simp only [getLsbD_zeroExtend, Fin.is_lt, decide_True, Bool.true_and]
  have p := lt_of_getLsbD x i
  revert p
  cases getLsbD x i <;> simp; omega

@[simp] theorem truncate_truncate_of_le (x : BitVec w) (h : k ≤ l) :
    (x.truncate l).truncate k = x.truncate k :=
  zeroExtend_zeroExtend_of_le x h

/-- Truncating by the bitwidth has no effect. -/
-- This doesn't need to be a `@[simp]` lemma, as `zeroExtend_eq` applies.
theorem truncate_eq_self {x : BitVec w} : x.truncate w = x := zeroExtend_eq _

@[simp] theorem truncate_cast {h : w = v} : (cast h x).truncate k = x.truncate k := by
  apply eq_of_getLsbD_eq
  simp

theorem msb_zeroExtend (x : BitVec w) : (x.zeroExtend v).msb = (decide (0 < v) && x.getLsbD (v - 1)) := by
  rw [msb_eq_getLsbD_last]
  simp only [getLsbD_zeroExtend]
  cases getLsbD x (v - 1) <;> simp; omega

theorem msb_zeroExtend' (x : BitVec w) (h : w ≤ v) : (x.zeroExtend' h).msb = (decide (0 < v) && x.getLsbD (v - 1)) := by
  rw [zeroExtend'_eq, msb_zeroExtend]

/-- zero extending a bitvector to width 1 equals the boolean of the lsb. -/
theorem zeroExtend_one_eq_ofBool_getLsb_zero (x : BitVec w) :
    x.zeroExtend 1 = BitVec.ofBool (x.getLsbD 0) := by
  ext i
  simp [getLsbD_zeroExtend, Fin.fin_one_eq_zero i]

/-- Zero extending `1#v` to `1#w` equals `1#w` when `v > 0`. -/
theorem zeroExtend_ofNat_one_eq_ofNat_one_of_lt {v w : Nat} (hv : 0 < v) :
    (BitVec.ofNat v 1).zeroExtend w = BitVec.ofNat w 1 := by
  ext ⟨i, hilt⟩
  simp only [getLsbD_zeroExtend, hilt, decide_True, getLsbD_ofNat, Bool.true_and,
    Bool.and_iff_right_iff_imp, decide_eq_true_eq]
  intros hi₁
  have hv := Nat.testBit_one_eq_true_iff_self_eq_zero.mp hi₁
  omega

/-- Truncating to width 1 produces a bitvector equal to the least significant bit. -/
theorem truncate_one {x : BitVec w} :
    x.truncate 1 = ofBool (x.getLsbD 0) := by
  ext i
  simp [show i = 0 by omega]

/-! ## extractLsb -/

@[simp]
protected theorem extractLsb_ofFin {n} (x : Fin (2^n)) (hi lo : Nat) :
  extractLsb hi lo (@BitVec.ofFin n x) = .ofNat (hi-lo+1) (x.val >>> lo) := rfl

@[simp]
protected theorem extractLsb_ofNat (x n : Nat) (hi lo : Nat) :
  extractLsb hi lo (BitVec.ofNat n x) = .ofNat (hi - lo + 1) ((x % 2^n) >>> lo) := by
  apply eq_of_getLsbD_eq
  intro ⟨i, _lt⟩
  simp [BitVec.ofNat]

@[simp] theorem extractLsb'_toNat (s m : Nat) (x : BitVec n) :
  (extractLsb' s m x).toNat = (x.toNat >>> s) % 2^m := rfl

@[simp] theorem extractLsb_toNat (hi lo : Nat) (x : BitVec n) :
  (extractLsb hi lo x).toNat = (x.toNat >>> lo) % 2^(hi-lo+1) := rfl

@[simp] theorem getLsbD_extractLsb' (start len : Nat) (x : BitVec n) (i : Nat) :
    (extractLsb' start len x).getLsbD i = (i < len && x.getLsbD (start+i)) := by
  simp [getLsbD, Nat.lt_succ]

@[simp] theorem getLsbD_extract (hi lo : Nat) (x : BitVec n) (i : Nat) :
    getLsbD (extractLsb hi lo x) i = (i ≤ (hi-lo) && getLsbD x (lo+i)) := by
  simp [getLsbD, Nat.lt_succ]

theorem extractLsb'_eq_extractLsb {w : Nat} (x : BitVec w) (start len : Nat) (h : len > 0) :
    x.extractLsb' start len = (x.extractLsb (len - 1 + start) start).cast (by omega) := by
  apply eq_of_toNat_eq
  simp [extractLsb, show len - 1 + 1 = len by omega]

/-! ### allOnes -/

@[simp] theorem toNat_allOnes : (allOnes v).toNat = 2^v - 1 := by
  unfold allOnes
  simp

@[simp] theorem getLsbD_allOnes : (allOnes v).getLsbD i = decide (i < v) := by
  simp [allOnes]

@[simp] theorem ofFin_add_rev (x : Fin (2^n)) : ofFin (x + x.rev) = allOnes n := by
  ext
  simp only [Fin.rev, getLsbD_ofFin, getLsbD_allOnes, Fin.is_lt, decide_True]
  rw [Fin.add_def]
  simp only [Nat.testBit_mod_two_pow, Fin.is_lt, decide_True, Bool.true_and]
  have h : (x : Nat) + (2 ^ n - (x + 1)) = 2 ^ n - 1 := by omega
  rw [h, Nat.testBit_two_pow_sub_one]
  simp

/-! ### or -/

@[simp] theorem toNat_or (x y : BitVec v) :
    BitVec.toNat (x ||| y) = BitVec.toNat x ||| BitVec.toNat y := rfl

@[simp] theorem toFin_or (x y : BitVec v) :
    BitVec.toFin (x ||| y) = BitVec.toFin x ||| BitVec.toFin y := by
  apply Fin.eq_of_val_eq
  exact (Nat.mod_eq_of_lt <| Nat.or_lt_two_pow x.isLt y.isLt).symm

@[simp] theorem getLsbD_or {x y : BitVec v} : (x ||| y).getLsbD i = (x.getLsbD i || y.getLsbD i) := by
  rw [← testBit_toNat, getLsbD, getLsbD]
  simp

@[simp] theorem getMsbD_or {x y : BitVec w} : (x ||| y).getMsbD i = (x.getMsbD i || y.getMsbD i) := by
  simp only [getMsbD]
  by_cases h : i < w <;> simp [h]

@[simp] theorem msb_or {x y : BitVec w} : (x ||| y).msb = (x.msb || y.msb) := by
  simp [BitVec.msb]

@[simp] theorem truncate_or {x y : BitVec w} :
    (x ||| y).truncate k = x.truncate k ||| y.truncate k := by
  ext
  simp

theorem or_assoc (x y z : BitVec w) :
    x ||| y ||| z = x ||| (y ||| z) := by
  ext i
  simp [Bool.or_assoc]
instance : Std.Associative (α := BitVec n) (· ||| ·) := ⟨BitVec.or_assoc⟩

theorem or_comm (x y : BitVec w) :
    x ||| y = y ||| x := by
  ext i
  simp [Bool.or_comm]
instance : Std.Commutative (fun (x y : BitVec w) => x ||| y) := ⟨BitVec.or_comm⟩

/-! ### and -/

@[simp] theorem toNat_and (x y : BitVec v) :
    BitVec.toNat (x &&& y) = BitVec.toNat x &&& BitVec.toNat y := rfl

@[simp] theorem toFin_and (x y : BitVec v) :
    BitVec.toFin (x &&& y) = BitVec.toFin x &&& BitVec.toFin y := by
  apply Fin.eq_of_val_eq
  exact (Nat.mod_eq_of_lt <| Nat.and_lt_two_pow _ y.isLt).symm

@[simp] theorem getLsbD_and {x y : BitVec v} : (x &&& y).getLsbD i = (x.getLsbD i && y.getLsbD i) := by
  rw [← testBit_toNat, getLsbD, getLsbD]
  simp

@[simp] theorem getMsbD_and {x y : BitVec w} : (x &&& y).getMsbD i = (x.getMsbD i && y.getMsbD i) := by
  simp only [getMsbD]
  by_cases h : i < w <;> simp [h]

@[simp] theorem msb_and {x y : BitVec w} : (x &&& y).msb = (x.msb && y.msb) := by
  simp [BitVec.msb]

@[simp] theorem truncate_and {x y : BitVec w} :
    (x &&& y).truncate k = x.truncate k &&& y.truncate k := by
  ext
  simp

theorem and_assoc (x y z : BitVec w) :
    x &&& y &&& z = x &&& (y &&& z) := by
  ext i
  simp [Bool.and_assoc]
instance : Std.Associative (α := BitVec n) (· &&& ·) := ⟨BitVec.and_assoc⟩

theorem and_comm (x y : BitVec w) :
    x &&& y = y &&& x := by
  ext i
  simp [Bool.and_comm]
instance : Std.Commutative (fun (x y : BitVec w) => x &&& y) := ⟨BitVec.and_comm⟩

/-! ### xor -/

@[simp] theorem toNat_xor (x y : BitVec v) :
    BitVec.toNat (x ^^^ y) = BitVec.toNat x ^^^ BitVec.toNat y := rfl

@[simp] theorem toFin_xor (x y : BitVec v) :
    BitVec.toFin (x ^^^ y) = BitVec.toFin x ^^^ BitVec.toFin y := by
  apply Fin.eq_of_val_eq
  exact (Nat.mod_eq_of_lt <| Nat.xor_lt_two_pow x.isLt y.isLt).symm

@[simp] theorem getLsbD_xor {x y : BitVec v} :
    (x ^^^ y).getLsbD i = (xor (x.getLsbD i) (y.getLsbD i)) := by
  rw [← testBit_toNat, getLsbD, getLsbD]
  simp

@[simp] theorem getMsbD_xor {x y : BitVec w} :
    (x ^^^ y).getMsbD i = (xor (x.getMsbD i) (y.getMsbD i)) := by
  simp only [getMsbD]
  by_cases h : i < w <;> simp [h]

@[simp] theorem msb_xor {x y : BitVec w} :
    (x ^^^ y).msb = (xor x.msb y.msb) := by
  simp [BitVec.msb]

@[simp] theorem truncate_xor {x y : BitVec w} :
    (x ^^^ y).truncate k = x.truncate k ^^^ y.truncate k := by
  ext
  simp

theorem xor_assoc (x y z : BitVec w) :
    x ^^^ y ^^^ z = x ^^^ (y ^^^ z) := by
  ext i
  simp [Bool.xor_assoc]
instance : Std.Associative (fun (x y : BitVec w) => x ^^^ y) := ⟨BitVec.xor_assoc⟩

theorem xor_comm (x y : BitVec w) :
    x ^^^ y = y ^^^ x := by
  ext i
  simp [Bool.xor_comm]
instance : Std.Commutative (fun (x y : BitVec w) => x ^^^ y) := ⟨BitVec.xor_comm⟩

/-! ### not -/

theorem not_def {x : BitVec v} : ~~~x = allOnes v ^^^ x := rfl

@[simp, bv_toNat] theorem toNat_not {x : BitVec v} : (~~~x).toNat = 2^v - 1 - x.toNat := by
  rw [Nat.sub_sub, Nat.add_comm, not_def, toNat_xor]
  apply Nat.eq_of_testBit_eq
  intro i
  simp only [toNat_allOnes, Nat.testBit_xor, Nat.testBit_two_pow_sub_one]
  match h : BitVec.toNat x with
  | 0 => simp
  | y+1 =>
    rw [Nat.succ_eq_add_one] at h
    rw [← h]
    rw [Nat.testBit_two_pow_sub_succ (isLt _)]
    · cases w : decide (i < v)
      · simp at w
        simp [w]
        rw [Nat.testBit_lt_two_pow]
        calc BitVec.toNat x < 2 ^ v := isLt _
          _ ≤ 2 ^ i := Nat.pow_le_pow_of_le_right Nat.zero_lt_two w
      · simp

@[simp] theorem toFin_not (x : BitVec w) :
    (~~~x).toFin = x.toFin.rev := by
  apply Fin.val_inj.mp
  simp only [val_toFin, toNat_not, Fin.val_rev]
  omega

@[simp] theorem getLsbD_not {x : BitVec v} : (~~~x).getLsbD i = (decide (i < v) && ! x.getLsbD i) := by
  by_cases h' : i < v <;> simp_all [not_def]

@[simp] theorem truncate_not {x : BitVec w} (h : k ≤ w) :
    (~~~x).truncate k = ~~~(x.truncate k) := by
  ext
  simp [h]
  omega

@[simp] theorem not_zero : ~~~(0#n) = allOnes n := by
  ext
  simp

/-! ### cast -/

@[simp] theorem not_cast {x : BitVec w} (h : w = w') : ~~~(cast h x) = cast h (~~~x) := by
  ext
  simp_all [lt_of_getLsbD]

@[simp] theorem and_cast {x y : BitVec w} (h : w = w') : cast h x &&& cast h y = cast h (x &&& y) := by
  ext
  simp_all [lt_of_getLsbD]

@[simp] theorem or_cast {x y : BitVec w} (h : w = w') : cast h x ||| cast h y = cast h (x ||| y) := by
  ext
  simp_all [lt_of_getLsbD]

@[simp] theorem xor_cast {x y : BitVec w} (h : w = w') : cast h x ^^^ cast h y = cast h (x ^^^ y) := by
  ext
  simp_all [lt_of_getLsbD]

/-! ### shiftLeft -/

@[simp, bv_toNat] theorem toNat_shiftLeft {x : BitVec v} :
    BitVec.toNat (x <<< n) = BitVec.toNat x <<< n % 2^v :=
  BitVec.toNat_ofNat _ _

@[simp] theorem toFin_shiftLeft {n : Nat} (x : BitVec w) :
    BitVec.toFin (x <<< n) = Fin.ofNat' (x.toNat <<< n) (Nat.two_pow_pos w) := rfl

@[simp]
theorem shiftLeft_zero_eq (x : BitVec w) : x <<< 0 = x := by
  apply eq_of_toNat_eq
  simp

@[simp]
theorem zero_shiftLeft (n : Nat) : 0#w <<< n = 0#w := by
  simp [bv_toNat]

@[simp] theorem getLsbD_shiftLeft (x : BitVec m) (n) :
    getLsbD (x <<< n) i = (decide (i < m) && !decide (i < n) && getLsbD x (i - n)) := by
  rw [← testBit_toNat, getLsbD]
  simp only [toNat_shiftLeft, Nat.testBit_mod_two_pow, Nat.testBit_shiftLeft, ge_iff_le]
  -- This step could be a case bashing tactic.
  cases h₁ : decide (i < m) <;> cases h₂ : decide (n ≤ i) <;> cases h₃ : decide (i < n)
  all_goals { simp_all <;> omega }

theorem shiftLeft_xor_distrib (x y : BitVec w) (n : Nat) :
    (x ^^^ y) <<< n = (x <<< n) ^^^ (y <<< n) := by
  ext i
  simp only [getLsbD_shiftLeft, Fin.is_lt, decide_True, Bool.true_and, getLsbD_xor]
  by_cases h : i < n
    <;> simp [h]

theorem shiftLeft_and_distrib (x y : BitVec w) (n : Nat) :
    (x &&& y) <<< n = (x <<< n) &&& (y <<< n) := by
  ext i
  simp only [getLsbD_shiftLeft, Fin.is_lt, decide_True, Bool.true_and, getLsbD_and]
  by_cases h : i < n
    <;> simp [h]

theorem shiftLeft_or_distrib (x y : BitVec w) (n : Nat) :
    (x ||| y) <<< n = (x <<< n) ||| (y <<< n) := by
  ext i
  simp only [getLsbD_shiftLeft, Fin.is_lt, decide_True, Bool.true_and, getLsbD_or]
  by_cases h : i < n
    <;> simp [h]

@[simp] theorem getMsbD_shiftLeft (x : BitVec w) (i) :
    (x <<< i).getMsbD k = x.getMsbD (k + i) := by
  simp only [getMsbD, getLsbD_shiftLeft]
  by_cases h : w = 0
  · subst h; simp
  have t : w - 1 - k < w := by omega
  simp only [t]
  simp only [decide_True, Nat.sub_sub, Bool.true_and, Nat.add_assoc]
  by_cases h₁ : k < w <;> by_cases h₂ : w - (1 + k) < i <;> by_cases h₃ : k + i < w
    <;> simp [h₁, h₂, h₃]
    <;> (first | apply getLsbD_ge | apply Eq.symm; apply getLsbD_ge)
    <;> omega

theorem shiftLeftZeroExtend_eq {x : BitVec w} :
    shiftLeftZeroExtend x n = zeroExtend (w+n) x <<< n := by
  apply eq_of_toNat_eq
  rw [shiftLeftZeroExtend, zeroExtend]
  split
  · simp
    rw [Nat.mod_eq_of_lt]
    rw [Nat.shiftLeft_eq, Nat.pow_add]
    exact Nat.mul_lt_mul_of_pos_right x.isLt (Nat.two_pow_pos _)
  · omega

@[simp] theorem getLsbD_shiftLeftZeroExtend (x : BitVec m) (n : Nat) :
    getLsbD (shiftLeftZeroExtend x n) i = ((! decide (i < n)) && getLsbD x (i - n)) := by
  rw [shiftLeftZeroExtend_eq]
  simp only [getLsbD_shiftLeft, getLsbD_zeroExtend]
  cases h₁ : decide (i < n) <;> cases h₂ : decide (i - n < m + n) <;> cases h₃ : decide (i < m + n)
    <;> simp_all
    <;> (rw [getLsbD_ge]; omega)

@[simp] theorem getMsbD_shiftLeftZeroExtend (x : BitVec m) (n : Nat) :
    getMsbD (shiftLeftZeroExtend x n) i = getMsbD x i := by
  have : n ≤ i + n := by omega
  simp_all [shiftLeftZeroExtend_eq]

@[simp] theorem msb_shiftLeftZeroExtend (x : BitVec w) (i : Nat) :
    (shiftLeftZeroExtend x i).msb = x.msb := by
  simp [shiftLeftZeroExtend_eq, BitVec.msb]

theorem shiftLeft_add {w : Nat} (x : BitVec w) (n m : Nat) :
    x <<< (n + m) = (x <<< n) <<< m := by
  ext i
  simp only [getLsbD_shiftLeft, Fin.is_lt, decide_True, Bool.true_and]
  rw [show i - (n + m) = (i - m - n) by omega]
  cases h₂ : decide (i < m) <;>
  cases h₃ : decide (i - m < w) <;>
  cases h₄ : decide (i - m < n) <;>
  cases h₅ : decide (i < n + m) <;>
    simp at * <;> omega

@[deprecated shiftLeft_add (since := "2024-06-02")]
theorem shiftLeft_shiftLeft {w : Nat} (x : BitVec w) (n m : Nat) :
    (x <<< n) <<< m = x <<< (n + m) := by
  rw [shiftLeft_add]

/-! ### shiftLeft reductions from BitVec to Nat -/

@[simp]
theorem shiftLeft_eq' {x : BitVec w₁} {y : BitVec w₂} : x <<< y = x <<< y.toNat := by rfl

theorem shiftLeft_zero' {x : BitVec w₁} : x <<< 0#w₂ = x := by simp

theorem shiftLeft_shiftLeft' {x : BitVec w₁} {y : BitVec w₂} {z : BitVec w₃} :
    x <<< y <<< z = x <<< (y.toNat + z.toNat) := by
  simp [shiftLeft_add]

theorem getLsbD_shiftLeft' {x : BitVec w₁} {y : BitVec w₂} {i : Nat} :
    (x <<< y).getLsbD i = (decide (i < w₁) && !decide (i < y.toNat) && x.getLsbD (i - y.toNat)) := by
  simp [shiftLeft_eq', getLsbD_shiftLeft]

/-! ### ushiftRight -/

@[simp, bv_toNat] theorem toNat_ushiftRight (x : BitVec n) (i : Nat) :
    (x >>> i).toNat = x.toNat >>> i := rfl

@[simp] theorem getLsbD_ushiftRight (x : BitVec n) (i j : Nat) :
    getLsbD (x >>> i) j = getLsbD x (i+j) := by
  unfold getLsbD ; simp

theorem ushiftRight_xor_distrib (x y : BitVec w) (n : Nat) :
    (x ^^^ y) >>> n = (x >>> n) ^^^ (y >>> n) := by
  ext
  simp

theorem ushiftRight_and_distrib (x y : BitVec w) (n : Nat) :
    (x &&& y) >>> n = (x >>> n) &&& (y >>> n) := by
  ext
  simp

theorem ushiftRight_or_distrib (x y : BitVec w)  (n : Nat) :
    (x ||| y) >>> n = (x >>> n) ||| (y >>> n) := by
  ext
  simp

@[simp]
theorem ushiftRight_zero_eq (x : BitVec w) : x >>> 0 = x := by
  simp [bv_toNat]

/-! ### ushiftRight reductions from BitVec to Nat -/

@[simp]
theorem ushiftRight_eq' (x : BitVec w₁) (y : BitVec w₂) :
    x >>> y = x >>> y.toNat := by rfl

/-! ### sshiftRight -/

theorem sshiftRight_eq {x : BitVec n} {i : Nat} :
    x.sshiftRight i = BitVec.ofInt n (x.toInt >>> i) := by
  apply BitVec.eq_of_toInt_eq
  simp [BitVec.sshiftRight]

/-- if the msb is false, the arithmetic shift right equals logical shift right -/
theorem sshiftRight_eq_of_msb_false {x : BitVec w} {s : Nat} (h : x.msb = false) :
    (x.sshiftRight s) = x >>> s := by
  apply BitVec.eq_of_toNat_eq
  rw [BitVec.sshiftRight_eq, BitVec.toInt_eq_toNat_cond]
  have hxbound : 2 * x.toNat < 2 ^ w := BitVec.msb_eq_false_iff_two_mul_lt.mp h
  simp only [hxbound, ↓reduceIte, Int.natCast_shiftRight, Int.ofNat_eq_coe, ofInt_natCast,
    toNat_ofNat, toNat_ushiftRight]
  replace hxbound : x.toNat >>> s < 2 ^ w := by
    rw [Nat.shiftRight_eq_div_pow]
    exact Nat.lt_of_le_of_lt (Nat.div_le_self ..) x.isLt
  apply Nat.mod_eq_of_lt hxbound

/--
If the msb is `true`, the arithmetic shift right equals negating,
then logical shifting right, then negating again.
The double negation preserves the lower bits that have been shifted,
and the outer negation ensures that the high bits are '1'. -/
theorem sshiftRight_eq_of_msb_true {x : BitVec w} {s : Nat} (h : x.msb = true) :
    (x.sshiftRight s) = ~~~((~~~x) >>> s) := by
  apply BitVec.eq_of_toNat_eq
  rcases w with rfl | w
  · simp [toNat_of_zero_length]
  · rw [BitVec.sshiftRight_eq, BitVec.toInt_eq_toNat_cond]
    have hxbound : (2 * x.toNat ≥ 2 ^ (w + 1)) := BitVec.msb_eq_true_iff_two_mul_ge.mp h
    replace hxbound : ¬ (2 * x.toNat < 2 ^ (w + 1)) := by omega
    simp only [hxbound, ↓reduceIte, toNat_ofInt, toNat_not, toNat_ushiftRight]
    rw [← Int.subNatNat_eq_coe, Int.subNatNat_of_lt (by omega),
        Nat.pred_eq_sub_one, Int.negSucc_shiftRight,
        Int.emod_negSucc, Int.natAbs_ofNat, Nat.succ_eq_add_one,
        Int.subNatNat_of_le (by omega), Int.toNat_ofNat, Nat.mod_eq_of_lt,
        Nat.sub_right_comm]
    omega
    · rw [Nat.shiftRight_eq_div_pow]
      apply Nat.lt_of_le_of_lt (Nat.div_le_self _ _) (by omega)

@[simp] theorem getLsbD_sshiftRight (x : BitVec w) (s i : Nat) :
    getLsbD (x.sshiftRight s) i =
      (!decide (w ≤ i) && if s + i < w then x.getLsbD (s + i) else x.msb) := by
  rcases hmsb : x.msb with rfl | rfl
  · simp only [sshiftRight_eq_of_msb_false hmsb, getLsbD_ushiftRight, Bool.if_false_right]
    by_cases hi : i ≥ w
    · simp only [hi, decide_True, Bool.not_true, Bool.false_and]
      apply getLsbD_ge
      omega
    · simp only [hi, decide_False, Bool.not_false, Bool.true_and, Bool.iff_and_self,
        decide_eq_true_eq]
      intros hlsb
      apply BitVec.lt_of_getLsbD _ _ hlsb
  · by_cases hi : i ≥ w
    · simp [hi]
    · simp only [sshiftRight_eq_of_msb_true hmsb, getLsbD_not, getLsbD_ushiftRight, Bool.not_and,
        Bool.not_not, hi, decide_False, Bool.not_false, Bool.if_true_right, Bool.true_and,
        Bool.and_iff_right_iff_imp, Bool.or_eq_true, Bool.not_eq_true', decide_eq_false_iff_not,
        Nat.not_lt, decide_eq_true_eq]
      omega

theorem sshiftRight_xor_distrib (x y : BitVec w) (n : Nat) :
    (x ^^^ y).sshiftRight n = (x.sshiftRight n) ^^^ (y.sshiftRight n) := by
  ext i
  simp only [getLsbD_sshiftRight, getLsbD_xor, msb_xor]
  split
    <;> by_cases w ≤ i
    <;> simp [*]

theorem sshiftRight_and_distrib (x y : BitVec w) (n : Nat) :
    (x &&& y).sshiftRight n = (x.sshiftRight n) &&& (y.sshiftRight n) := by
  ext i
  simp only [getLsbD_sshiftRight, getLsbD_and, msb_and]
  split
    <;> by_cases w ≤ i
    <;> simp [*]

theorem sshiftRight_or_distrib (x y : BitVec w) (n : Nat) :
    (x ||| y).sshiftRight n = (x.sshiftRight n) ||| (y.sshiftRight n) := by
  ext i
  simp only [getLsbD_sshiftRight, getLsbD_or, msb_or]
  split
    <;> by_cases w ≤ i
    <;> simp [*]

/-- The msb after arithmetic shifting right equals the original msb. -/
theorem sshiftRight_msb_eq_msb {n : Nat} {x : BitVec w} :
    (x.sshiftRight n).msb = x.msb := by
  rw [msb_eq_getLsbD_last, getLsbD_sshiftRight, msb_eq_getLsbD_last]
  by_cases hw₀ : w = 0
  · simp [hw₀]
  · simp only [show ¬(w ≤ w - 1) by omega, decide_False, Bool.not_false, Bool.true_and,
      ite_eq_right_iff]
    intros h
    simp [show n = 0 by omega]

@[simp] theorem sshiftRight_zero {x : BitVec w} : x.sshiftRight 0 = x := by
  ext i
  simp

theorem sshiftRight_add {x : BitVec w} {m n : Nat} :
    x.sshiftRight (m + n) = (x.sshiftRight m).sshiftRight n := by
  ext i
  simp only [getLsbD_sshiftRight, Nat.add_assoc]
  by_cases h₁ : w ≤ (i : Nat)
  · simp [h₁]
  · simp only [h₁, decide_False, Bool.not_false, Bool.true_and]
    by_cases h₂ : n + ↑i < w
    · simp [h₂]
    · simp only [h₂, ↓reduceIte]
      by_cases h₃ : m + (n + ↑i) < w
      · simp [h₃]
        omega
      · simp [h₃, sshiftRight_msb_eq_msb]

/-! ### sshiftRight reductions from BitVec to Nat -/

@[simp]
theorem sshiftRight_eq' (x : BitVec w) : x.sshiftRight' y = x.sshiftRight y.toNat := rfl

/-! ### udiv -/

theorem udiv_eq {x y : BitVec n} : x.udiv y = BitVec.ofNat n (x.toNat / y.toNat) := by
  have h : x.toNat / y.toNat < 2 ^ n := Nat.lt_of_le_of_lt (Nat.div_le_self ..) (by omega)
  simp [udiv, bv_toNat, h, Nat.mod_eq_of_lt]

@[simp, bv_toNat]
theorem toNat_udiv {x y : BitVec n} : (x.udiv y).toNat = x.toNat / y.toNat := by
  simp only [udiv_eq]
  by_cases h : y = 0
  · simp [h]
  · rw [toNat_ofNat, Nat.mod_eq_of_lt]
    exact Nat.lt_of_le_of_lt (Nat.div_le_self ..) (by omega)

/-! ### umod -/

theorem umod_eq {x y : BitVec n} :
    x.umod y = BitVec.ofNat n (x.toNat % y.toNat) := by
  have h : x.toNat % y.toNat < 2 ^ n := Nat.lt_of_le_of_lt (Nat.mod_le _ _) x.isLt
  simp [umod, bv_toNat, Nat.mod_eq_of_lt h]

@[simp, bv_toNat]
theorem toNat_umod {x y : BitVec n} :
    (x.umod y).toNat = x.toNat % y.toNat := rfl

/-! ### signExtend -/

/-- Equation theorem for `Int.sub` when both arguments are `Int.ofNat` -/
private theorem Int.ofNat_sub_ofNat_of_lt {n m : Nat} (hlt : n < m) :
    (n : Int) - (m : Int) = -(↑(m - 1 - n) + 1) := by
  omega

/-- Equation theorem for `Int.mod` -/
private theorem Int.negSucc_emod (m : Nat) (n : Int) :
    -(m + 1) % n = Int.subNatNat (Int.natAbs n) ((m % Int.natAbs n) + 1) := rfl

/-- The sign extension is the same as zero extending when `msb = false`. -/
theorem signExtend_eq_not_zeroExtend_not_of_msb_false {x : BitVec w} {v : Nat} (hmsb : x.msb = false) :
    x.signExtend v = x.zeroExtend v := by
  ext i
  by_cases hv : i < v
  · simp only [signExtend, getLsbD, getLsbD_zeroExtend, hv, decide_True, Bool.true_and, toNat_ofInt,
      BitVec.toInt_eq_msb_cond, hmsb, ↓reduceIte, reduceCtorEq]
    rw [Int.ofNat_mod_ofNat, Int.toNat_ofNat, Nat.testBit_mod_two_pow]
    simp [BitVec.testBit_toNat]
  · simp only [getLsbD_zeroExtend, hv, decide_False, Bool.false_and]
    apply getLsbD_ge
    omega

/--
The sign extension is a bitwise not, followed by a zero extend, followed by another bitwise not
when `msb = true`. The double bitwise not ensures that the high bits are '1',
and the lower bits are preserved. -/
theorem signExtend_eq_not_zeroExtend_not_of_msb_true {x : BitVec w} {v : Nat} (hmsb : x.msb = true) :
    x.signExtend v = ~~~((~~~x).zeroExtend v) := by
  apply BitVec.eq_of_toNat_eq
  simp only [signExtend, BitVec.toInt_eq_msb_cond, toNat_ofInt, toNat_not,
    toNat_truncate, hmsb, ↓reduceIte]
  norm_cast
  rw [Int.ofNat_sub_ofNat_of_lt, Int.negSucc_emod]
  simp only [Int.natAbs_ofNat, Nat.succ_eq_add_one]
  rw [Int.subNatNat_of_le]
  · rw [Int.toNat_ofNat, Nat.add_comm, Nat.sub_add_eq]
  · apply Nat.le_trans
    · apply Nat.succ_le_of_lt
      apply Nat.mod_lt
      apply Nat.two_pow_pos
    · apply Nat.le_refl
  · omega

@[simp] theorem getLsbD_signExtend (x  : BitVec w) {v i : Nat} :
    (x.signExtend v).getLsbD i = (decide (i < v) && if i < w then x.getLsbD i else x.msb) := by
  rcases hmsb : x.msb with rfl | rfl
  · rw [signExtend_eq_not_zeroExtend_not_of_msb_false hmsb]
    by_cases (i < v) <;> by_cases (i < w) <;> simp_all <;> omega
  · rw [signExtend_eq_not_zeroExtend_not_of_msb_true hmsb]
    by_cases (i < v) <;> by_cases (i < w) <;> simp_all <;> omega

/-- Sign extending to a width smaller than the starting width is a truncation. -/
theorem signExtend_eq_truncate_of_lt (x : BitVec w) {v : Nat} (hv : v ≤ w):
  x.signExtend v = x.truncate v := by
  ext i
  simp only [getLsbD_signExtend, Fin.is_lt, decide_True, Bool.true_and, getLsbD_zeroExtend,
    ite_eq_left_iff, Nat.not_lt]
  omega

/-- Sign extending to the same bitwidth is a no op. -/
theorem signExtend_eq (x : BitVec w) : x.signExtend w = x := by
  rw [signExtend_eq_truncate_of_lt _ (Nat.le_refl _), truncate_eq]

/-! ### append -/

theorem append_def (x : BitVec v) (y : BitVec w) :
    x ++ y = (shiftLeftZeroExtend x w ||| zeroExtend' (Nat.le_add_left w v) y) := rfl

@[simp] theorem toNat_append (x : BitVec m) (y : BitVec n) :
    (x ++ y).toNat = x.toNat <<< n ||| y.toNat :=
  rfl

@[simp] theorem getLsbD_append {x : BitVec n} {y : BitVec m} :
    getLsbD (x ++ y) i = bif i < m then getLsbD y i else getLsbD x (i - m) := by
  simp only [append_def, getLsbD_or, getLsbD_shiftLeftZeroExtend, getLsbD_zeroExtend']
  by_cases h : i < m
  · simp [h]
  · simp [h]; simp_all

@[simp] theorem getMsbD_append {x : BitVec n} {y : BitVec m} :
    getMsbD (x ++ y) i = bif n ≤ i then getMsbD y (i - n) else getMsbD x i := by
  simp [append_def]
  by_cases h : n ≤ i
  · simp [h]
  · simp [h]

theorem msb_append {x : BitVec w} {y : BitVec v} :
    (x ++ y).msb = bif (w == 0) then (y.msb) else (x.msb) := by
  rw [← append_eq, append]
  simp [msb_zeroExtend']
  by_cases h : w = 0
  · subst h
    simp [BitVec.msb, getMsbD]
  · rw [cond_eq_if]
    have q : 0 < w + v := by omega
    have t : y.getLsbD (w + v - 1) = false := getLsbD_ge _ _ (by omega)
    simp [h, q, t, BitVec.msb, getMsbD]

@[simp] theorem append_zero_width (x : BitVec w) (y : BitVec 0) : x ++ y = x := by
  ext
  rw [getLsbD_append] -- Why does this not work with `simp [getLsbD_append]`?
  simp

@[simp] theorem zero_width_append (x : BitVec 0) (y : BitVec v) : x ++ y = cast (by omega) y := by
  ext
  rw [getLsbD_append]
  simpa using lt_of_getLsbD _ _

@[simp] theorem cast_append_right (h : w + v = w + v') (x : BitVec w) (y : BitVec v) :
    cast h (x ++ y) = x ++ cast (by omega) y := by
  ext
  simp only [getLsbD_cast, getLsbD_append, cond_eq_if, decide_eq_true_eq]
  split <;> split
  · rfl
  · omega
  · omega
  · congr
    omega

@[simp] theorem cast_append_left (h : w + v = w' + v) (x : BitVec w) (y : BitVec v) :
    cast h (x ++ y) = cast (by omega) x ++ y := by
  ext
  simp

theorem truncate_append {x : BitVec w} {y : BitVec v} :
    (x ++ y).truncate k = if h : k ≤ v then y.truncate k else (x.truncate (k - v) ++ y).cast (by omega) := by
  apply eq_of_getLsbD_eq
  intro i
  simp only [getLsbD_zeroExtend, Fin.is_lt, decide_True, getLsbD_append, Bool.true_and]
  split
  · have t : i < v := by omega
    simp [t]
  · by_cases t : i < v
    · simp [t]
    · have t' : i - v < k - v := by omega
      simp [t, t']

@[simp] theorem truncate_cons {x : BitVec w} : (cons a x).truncate w = x := by
  simp [cons, truncate_append]

@[simp] theorem not_append {x : BitVec w} {y : BitVec v} : ~~~ (x ++ y) = (~~~ x) ++ (~~~ y) := by
  ext i
  simp only [getLsbD_not, getLsbD_append, cond_eq_if]
  split
  · simp_all
  · simp_all; omega

@[simp] theorem and_append {x₁ x₂ : BitVec w} {y₁ y₂ : BitVec v} :
    (x₁ ++ y₁) &&& (x₂ ++ y₂) = (x₁ &&& x₂) ++ (y₁ &&& y₂) := by
  ext i
  simp only [getLsbD_append, cond_eq_if]
  split <;> simp [*]

@[simp] theorem or_append {x₁ x₂ : BitVec w} {y₁ y₂ : BitVec v} :
    (x₁ ++ y₁) ||| (x₂ ++ y₂) = (x₁ ||| x₂) ++ (y₁ ||| y₂) := by
  ext i
  simp only [getLsbD_append, cond_eq_if]
  split <;> simp [*]

@[simp] theorem xor_append {x₁ x₂ : BitVec w} {y₁ y₂ : BitVec v} :
    (x₁ ++ y₁) ^^^ (x₂ ++ y₂) = (x₁ ^^^ x₂) ++ (y₁ ^^^ y₂) := by
  ext i
  simp only [getLsbD_append, cond_eq_if]
  split <;> simp [*]

theorem shiftRight_add {w : Nat} (x : BitVec w) (n m : Nat) :
    x >>> (n + m) = (x >>> n) >>> m:= by
  ext i
  simp [Nat.add_assoc n m i]

@[deprecated shiftRight_add (since := "2024-06-02")]
theorem shiftRight_shiftRight {w : Nat} (x : BitVec w) (n m : Nat) :
    (x >>> n) >>> m = x >>> (n + m) := by
  rw [shiftRight_add]

/-! ### rev -/

theorem getLsbD_rev (x : BitVec w) (i : Fin w) :
    x.getLsbD i.rev = x.getMsbD i := by
  simp [getLsbD, getMsbD]
  congr 1
  omega

theorem getMsbD_rev (x : BitVec w) (i : Fin w) :
    x.getMsbD i.rev = x.getLsbD i := by
  simp only [← getLsbD_rev]
  simp only [Fin.rev]
  congr
  omega

/-! ### cons -/

@[simp] theorem toNat_cons (b : Bool) (x : BitVec w) :
    (cons b x).toNat = (b.toNat <<< w) ||| x.toNat := by
  let ⟨x, _⟩ := x
  simp [cons, toNat_append, toNat_ofBool]

/-- Variant of `toNat_cons` using `+` instead of `|||`. -/
theorem toNat_cons' {x : BitVec w} :
    (cons a x).toNat = (a.toNat <<< w) + x.toNat := by
  simp [cons, Nat.shiftLeft_eq, Nat.mul_comm _ (2^w), Nat.mul_add_lt_is_or, x.isLt]

@[simp] theorem getLsbD_cons (b : Bool) {n} (x : BitVec n) (i : Nat) :
    getLsbD (cons b x) i = if i = n then b else getLsbD x i := by
  simp only [getLsbD, toNat_cons, Nat.testBit_or]
  rw [Nat.testBit_shiftLeft]
  rcases Nat.lt_trichotomy i n with i_lt_n | i_eq_n | n_lt_i
  · have p1 : ¬(n ≤ i) := by omega
    have p2 : i ≠ n := by omega
    simp [p1, p2]
  · simp [i_eq_n, testBit_toNat]
    cases b <;> trivial
  · have p1 : i ≠ n := by omega
    have p2 : i - n ≠ 0 := by omega
    simp [p1, p2, Nat.testBit_bool_to_nat]

@[simp] theorem msb_cons : (cons a x).msb = a := by
  simp [cons, msb_cast, msb_append]

@[simp] theorem getMsbD_cons_zero : (cons a x).getMsbD 0 = a := by
  rw [← BitVec.msb, msb_cons]

@[simp] theorem getMsbD_cons_succ : (cons a x).getMsbD (i + 1) = x.getMsbD i := by
  simp [cons, Nat.le_add_left 1 i]

theorem truncate_succ (x : BitVec w) :
    truncate (i+1) x = cons (getLsbD x i) (truncate i x) := by
  apply eq_of_getLsbD_eq
  intro j
  simp only [getLsbD_truncate, getLsbD_cons, j.isLt, decide_True, Bool.true_and]
  if j_eq : j.val = i then
    simp [j_eq]
  else
    have j_lt : j.val < i := Nat.lt_of_le_of_ne (Nat.le_of_succ_le_succ j.isLt) j_eq
    simp [j_eq, j_lt]

theorem eq_msb_cons_truncate (x : BitVec (w+1)) : x = (cons x.msb (x.truncate w)) := by
  ext i
  simp
  split <;> rename_i h
  · simp [BitVec.msb, getMsbD, h]
  · by_cases h' : i < w
    · simp_all
    · omega

@[simp] theorem not_cons (x : BitVec w) (b : Bool) : ~~~(cons b x) = cons (!b) (~~~x) := by
  simp [cons]

@[simp] theorem cons_or_cons (x y : BitVec w) (a b : Bool) :
    (cons a x) ||| (cons b y) = cons (a || b) (x ||| y) := by
  ext i; cases i using Fin.succRecOn <;> simp <;> split <;> rfl

@[simp] theorem cons_and_cons (x y : BitVec w) (a b : Bool) :
    (cons a x) &&& (cons b y) = cons (a && b) (x &&& y) := by
  ext i; cases i using Fin.succRecOn <;> simp <;> split <;> rfl

@[simp] theorem cons_xor_cons (x y : BitVec w) (a b : Bool) :
    (cons a x) ^^^ (cons b y) = cons (xor a b) (x ^^^ y) := by
  ext i; cases i using Fin.succRecOn <;> simp <;> split <;> rfl

/-! ### concat -/

@[simp] theorem toNat_concat (x : BitVec w) (b : Bool) :
    (concat x b).toNat = x.toNat * 2 + b.toNat := by
  apply Nat.eq_of_testBit_eq
  simp only [concat, toNat_append, Nat.shiftLeft_eq, Nat.pow_one, toNat_ofBool, Nat.testBit_or]
  cases b
  · simp
  · rintro (_ | i)
    <;> simp [Nat.add_mod, Nat.add_comm, Nat.add_mul_div_right, Nat.testBit_add_one]

theorem getLsbD_concat (x : BitVec w) (b : Bool) (i : Nat) :
    (concat x b).getLsbD i = if i = 0 then b else x.getLsbD (i - 1) := by
  simp only [concat, getLsbD, toNat_append, toNat_ofBool, Nat.testBit_or, Nat.shiftLeft_eq]
  cases i
  · simp [Nat.mod_eq_of_lt b.toNat_lt]
  · simp [Nat.div_eq_of_lt b.toNat_lt, Nat.testBit_add_one]

@[simp] theorem getLsbD_concat_zero : (concat x b).getLsbD 0 = b := by
  simp [getLsbD_concat]

@[simp] theorem getLsbD_concat_succ : (concat x b).getLsbD (i + 1) = x.getLsbD i := by
  simp [getLsbD_concat]

@[simp] theorem not_concat (x : BitVec w) (b : Bool) : ~~~(concat x b) = concat (~~~x) !b := by
  ext i; cases i using Fin.succRecOn <;> simp [*, Nat.succ_lt_succ]

@[simp] theorem concat_or_concat (x y : BitVec w) (a b : Bool) :
    (concat x a) ||| (concat y b) = concat (x ||| y) (a || b) := by
  ext i; cases i using Fin.succRecOn <;> simp

@[simp] theorem concat_and_concat (x y : BitVec w) (a b : Bool) :
    (concat x a) &&& (concat y b) = concat (x &&& y) (a && b) := by
  ext i; cases i using Fin.succRecOn <;> simp

@[simp] theorem concat_xor_concat (x y : BitVec w) (a b : Bool) :
    (concat x a) ^^^ (concat y b) = concat (x ^^^ y) (xor a b) := by
  ext i; cases i using Fin.succRecOn <;> simp

/-! ### add -/

theorem add_def {n} (x y : BitVec n) : x + y = .ofNat n (x.toNat + y.toNat) := rfl

/--
Definition of bitvector addition as a nat.
-/
@[simp, bv_toNat] theorem toNat_add (x y : BitVec w) : (x + y).toNat = (x.toNat + y.toNat) % 2^w := rfl
@[simp] theorem toFin_add (x y : BitVec w) : (x + y).toFin = toFin x + toFin y := rfl
@[simp] theorem ofFin_add (x : Fin (2^n)) (y : BitVec n) :
  .ofFin x + y = .ofFin (x + y.toFin) := rfl
@[simp] theorem add_ofFin (x : BitVec n) (y : Fin (2^n)) :
  x + .ofFin y = .ofFin (x.toFin + y) := rfl

theorem ofNat_add {n} (x y : Nat) : BitVec.ofNat n (x + y) = BitVec.ofNat n x + BitVec.ofNat n y := by
  apply eq_of_toNat_eq ; simp [BitVec.ofNat]

theorem ofNat_add_ofNat {n} (x y : Nat) : BitVec.ofNat n x + BitVec.ofNat n y = BitVec.ofNat n (x + y) :=
  (ofNat_add x y).symm

protected theorem add_assoc (x y z : BitVec n) : x + y + z = x + (y + z) := by
  apply eq_of_toNat_eq ; simp [Nat.add_assoc]
instance : Std.Associative (α := BitVec n) (· + ·) := ⟨BitVec.add_assoc⟩

protected theorem add_comm (x y : BitVec n) : x + y = y + x := by
  simp [add_def, Nat.add_comm]
instance : Std.Commutative (α := BitVec n) (· + ·) := ⟨BitVec.add_comm⟩

@[simp] protected theorem add_zero (x : BitVec n) : x + 0#n = x := by simp [add_def]

@[simp] protected theorem zero_add (x : BitVec n) : 0#n + x = x := by simp [add_def]
instance : Std.LawfulIdentity (α := BitVec n) (· + ·) 0#n where
  left_id := BitVec.zero_add
  right_id := BitVec.add_zero

theorem truncate_add (x y : BitVec w) (h : i ≤ w) :
    (x + y).truncate i = x.truncate i + y.truncate i := by
  have dvd : 2^i ∣ 2^w := Nat.pow_dvd_pow _ h
  simp [bv_toNat, h, Nat.mod_mod_of_dvd _ dvd]

@[simp, bv_toNat] theorem toInt_add (x y : BitVec w) :
  (x + y).toInt = (x.toInt + y.toInt).bmod (2^w) := by
  simp [toInt_eq_toNat_bmod]

theorem ofInt_add {n} (x y : Int) : BitVec.ofInt n (x + y) =
    BitVec.ofInt n x + BitVec.ofInt n y := by
  apply eq_of_toInt_eq
  simp

/-! ### sub/neg -/

theorem sub_def {n} (x y : BitVec n) : x - y = .ofNat n ((2^n - y.toNat) + x.toNat) := by rfl

@[simp] theorem toNat_sub {n} (x y : BitVec n) :
    (x - y).toNat = (((2^n - y.toNat) + x.toNat) % 2^n) := rfl

-- We prefer this lemma to `toNat_sub` for the `bv_toNat` simp set.
-- For reasons we don't yet understand, unfolding via `toNat_sub` sometimes
-- results in `omega` generating proof terms that are very slow in the kernel.
@[bv_toNat] theorem toNat_sub' {n} (x y : BitVec n) :
    (x - y).toNat = ((x.toNat + (2^n - y.toNat)) % 2^n) := by
  rw [toNat_sub, Nat.add_comm]

@[simp] theorem toFin_sub (x y : BitVec n) : (x - y).toFin = toFin x - toFin y := rfl

@[simp] theorem ofFin_sub (x : Fin (2^n)) (y : BitVec n) : .ofFin x - y = .ofFin (x - y.toFin) :=
  rfl
@[simp] theorem sub_ofFin (x : BitVec n) (y : Fin (2^n)) : x - .ofFin y = .ofFin (x.toFin - y) :=
  rfl
-- Remark: we don't use `[simp]` here because simproc` subsumes it for literals.
-- If `x` and `n` are not literals, applying this theorem eagerly may not be a good idea.
theorem ofNat_sub_ofNat {n} (x y : Nat) : BitVec.ofNat n x - BitVec.ofNat n y = .ofNat n ((2^n - y % 2^n) + x) := by
  apply eq_of_toNat_eq ; simp [BitVec.ofNat]

@[simp] protected theorem sub_zero (x : BitVec n) : x - 0#n = x := by apply eq_of_toNat_eq ; simp

@[simp] protected theorem sub_self (x : BitVec n) : x - x = 0#n := by
  apply eq_of_toNat_eq
  simp only [toNat_sub]
  rw [Nat.add_comm, Nat.add_sub_of_le]
  · simp
  · exact Nat.le_of_lt x.isLt

@[simp, bv_toNat] theorem toNat_neg (x : BitVec n) : (- x).toNat = (2^n - x.toNat) % 2^n := by
  simp [Neg.neg, BitVec.neg]

@[simp] theorem toFin_neg (x : BitVec n) :
    (-x).toFin = Fin.ofNat' (2^n - x.toNat) (Nat.two_pow_pos _) :=
  rfl

theorem sub_toAdd {n} (x y : BitVec n) : x - y = x + - y := by
  apply eq_of_toNat_eq
  simp
  rw [Nat.add_comm]

@[simp] theorem neg_zero (n:Nat) : -BitVec.ofNat n 0 = BitVec.ofNat n 0 := by apply eq_of_toNat_eq ; simp

theorem add_sub_cancel (x y : BitVec w) : x + y - y = x := by
  apply eq_of_toNat_eq
  have y_toNat_le := Nat.le_of_lt y.isLt
  rw [toNat_sub, toNat_add, Nat.add_comm, Nat.mod_add_mod, Nat.add_assoc, ← Nat.add_sub_assoc y_toNat_le,
      Nat.add_sub_cancel_left, Nat.add_mod_right, toNat_mod_cancel]

theorem sub_add_cancel (x y : BitVec w) : x - y + y = x := by
  rw [sub_toAdd, BitVec.add_assoc, BitVec.add_comm _ y,
      ← BitVec.add_assoc, ← sub_toAdd, add_sub_cancel]

theorem eq_sub_iff_add_eq {x y z : BitVec w} : x = z - y ↔ x + y = z := by
  apply Iff.intro <;> intro h
  · simp [h, sub_add_cancel]
  · simp [←h, add_sub_cancel]

theorem negOne_eq_allOnes : -1#w = allOnes w := by
  apply eq_of_toNat_eq
  if g : w = 0 then
    simp [g]
  else
    have q : 1 < 2^w := by simp [g]
    have r : (2^w - 1) < 2^w := by omega
    simp [Nat.mod_eq_of_lt q, Nat.mod_eq_of_lt r]

theorem neg_eq_not_add (x : BitVec w) : -x = ~~~x + 1 := by
  apply eq_of_toNat_eq
  simp only [toNat_neg, ofNat_eq_ofNat, toNat_add, toNat_not, toNat_ofNat, Nat.add_mod_mod]
  congr
  have hx : x.toNat < 2^w := x.isLt
  rw [Nat.sub_sub, Nat.add_comm 1 x.toNat, ← Nat.sub_sub, Nat.sub_add_cancel (by omega)]

@[simp]
theorem neg_neg {x : BitVec w} : - - x = x := by
  by_cases h : x = 0#w
  · simp [h]
  · simp [bv_toNat, h]

theorem neg_ne_iff_ne_neg {x y : BitVec w} : -x ≠ y ↔ x ≠ -y := by
  constructor
  all_goals
    intro h h'
    subst h'
    simp at h

/-! ### mul -/

theorem mul_def {n} {x y : BitVec n} : x * y = (ofFin <| x.toFin * y.toFin) := by rfl

@[simp, bv_toNat] theorem toNat_mul (x y : BitVec n) : (x * y).toNat = (x.toNat * y.toNat) % 2 ^ n := rfl
@[simp] theorem toFin_mul (x y : BitVec n) : (x * y).toFin = (x.toFin * y.toFin) := rfl

protected theorem mul_comm (x y : BitVec w) : x * y = y * x := by
  apply eq_of_toFin_eq; simpa using Fin.mul_comm ..
instance : Std.Commutative (fun (x y : BitVec w) => x * y) := ⟨BitVec.mul_comm⟩

protected theorem mul_assoc (x y z : BitVec w) : x * y * z = x * (y * z) := by
  apply eq_of_toFin_eq; simpa using Fin.mul_assoc ..
instance : Std.Associative (fun (x y : BitVec w) => x * y) := ⟨BitVec.mul_assoc⟩

@[simp] protected theorem mul_one (x : BitVec w) : x * 1#w = x := by
  cases w
  · apply Subsingleton.elim
  · apply eq_of_toNat_eq; simp [Nat.mod_eq_of_lt]

@[simp] protected theorem one_mul (x : BitVec w) : 1#w * x = x := by
  rw [BitVec.mul_comm, BitVec.mul_one]

instance : Std.LawfulCommIdentity (fun (x y : BitVec w) => x * y) (1#w) where
  right_id := BitVec.mul_one

@[simp]
theorem BitVec.mul_zero {x : BitVec w} : x * 0#w = 0#w := by
  apply eq_of_toNat_eq
  simp [toNat_mul]

theorem BitVec.mul_add {x y z : BitVec w} :
    x * (y + z) = x * y + x * z := by
  apply eq_of_toNat_eq
  simp only [toNat_mul, toNat_add, Nat.add_mod_mod, Nat.mod_add_mod]
  rw [Nat.mul_mod, Nat.mod_mod (y.toNat + z.toNat),
    ← Nat.mul_mod, Nat.mul_add]

@[simp, bv_toNat] theorem toInt_mul (x y : BitVec w) :
  (x * y).toInt = (x.toInt * y.toInt).bmod (2^w) := by
  simp [toInt_eq_toNat_bmod]

theorem ofInt_mul {n} (x y : Int) : BitVec.ofInt n (x * y) =
    BitVec.ofInt n x * BitVec.ofInt n y := by
  apply eq_of_toInt_eq
  simp

/-! ### le and lt -/

@[bv_toNat] theorem le_def {x y : BitVec n} :
  x ≤ y ↔ x.toNat ≤ y.toNat := Iff.rfl

@[simp] theorem le_ofFin {x : BitVec n} {y : Fin (2^n)} :
  x ≤ BitVec.ofFin y ↔ x.toFin ≤ y := Iff.rfl
@[simp] theorem ofFin_le {x : Fin (2^n)} {y : BitVec n} :
  BitVec.ofFin x ≤ y ↔ x ≤ y.toFin := Iff.rfl
@[simp] theorem ofNat_le_ofNat {n} {x y : Nat} : (BitVec.ofNat n x) ≤ (BitVec.ofNat n y) ↔ x % 2^n ≤ y % 2^n := by
  simp [le_def]

@[bv_toNat] theorem lt_def {x y : BitVec n} :
  x < y ↔ x.toNat < y.toNat := Iff.rfl

@[simp] theorem lt_ofFin {x : BitVec n} {y : Fin (2^n)} :
  x < BitVec.ofFin y ↔ x.toFin < y := Iff.rfl
@[simp] theorem ofFin_lt {x : Fin (2^n)} {y : BitVec n} :
  BitVec.ofFin x < y ↔ x < y.toFin := Iff.rfl
@[simp] theorem ofNat_lt_ofNat {n} (x y : Nat) : BitVec.ofNat n x < BitVec.ofNat n y ↔ x % 2^n < y % 2^n := by
  simp [lt_def]

@[simp] protected theorem not_le {x y : BitVec n} : ¬ x ≤ y ↔ y < x := by
  simp [le_def, lt_def]

@[simp] protected theorem not_lt {x y : BitVec n} : ¬ x < y ↔ y ≤ x := by
  simp [le_def, lt_def]

@[simp] protected theorem le_refl (x : BitVec n) : x ≤ x := by
  simp [le_def]

@[simp] protected theorem lt_irrefl (x : BitVec n) : ¬x < x := by
  simp [lt_def]

protected theorem le_trans {x y z : BitVec n} : x ≤ y → y ≤ z → x ≤ z := by
  simp only [le_def]
  apply Nat.le_trans

protected theorem lt_trans {x y z : BitVec n} : x < y → y < z → x < z := by
  simp only [lt_def]
  apply Nat.lt_trans

protected theorem le_total (x y : BitVec n) : x ≤ y ∨ y ≤ x := by
  simp only [le_def]
  apply Nat.le_total

protected theorem le_antisymm {x y : BitVec n} : x ≤ y → y ≤ x → x = y := by
  simp only [le_def, BitVec.toNat_eq]
  apply Nat.le_antisymm

protected theorem lt_asymm {x y : BitVec n} : x < y → ¬ y < x := by
  simp only [lt_def]
  apply Nat.lt_asymm

protected theorem lt_of_le_ne {x y : BitVec n} : x ≤ y → ¬ x = y → x < y := by
  simp only [lt_def, le_def, BitVec.toNat_eq]
  apply Nat.lt_of_le_of_ne

protected theorem ne_of_lt {x y : BitVec n} : x < y → x ≠ y := by
  simp only [lt_def, ne_eq, toNat_eq]
  apply Nat.ne_of_lt

protected theorem umod_lt (x : BitVec n) {y : BitVec n} : 0 < y → x.umod y < y := by
  simp only [ofNat_eq_ofNat, lt_def, toNat_ofNat, Nat.zero_mod, umod, toNat_ofNatLt]
  apply Nat.mod_lt

/-! ### ofBoolList -/

@[simp] theorem getMsbD_ofBoolListBE : (ofBoolListBE bs).getMsbD i = bs.getD i false := by
  induction bs generalizing i <;> cases i <;> simp_all [ofBoolListBE]

@[simp] theorem getLsbD_ofBoolListBE :
    (ofBoolListBE bs).getLsbD i = (decide (i < bs.length) && bs.getD (bs.length - 1 - i) false) := by
  simp [getLsbD_eq_getMsbD]

@[simp] theorem getLsb_ofBoolListLE : (ofBoolListLE bs).getLsbD i = bs.getD i false := by
  induction bs generalizing i <;> cases i <;> simp_all [ofBoolListLE]

@[simp] theorem getMsbD_ofBoolListLE :
    (ofBoolListLE bs).getMsbD i = (decide (i < bs.length) && bs.getD (bs.length - 1 - i) false) := by
  simp [getMsbD_eq_getLsbD]

/-! # Rotate Left -/

/-- rotateLeft is invariant under `mod` by the bitwidth. -/
@[simp]
theorem rotateLeft_mod_eq_rotateLeft {x : BitVec w} {r : Nat} :
    x.rotateLeft (r % w) = x.rotateLeft r := by
  simp only [rotateLeft, Nat.mod_mod]

/-- `rotateLeft` equals the bit fiddling definition of `rotateLeftAux` when the rotation amount is
smaller than the bitwidth. -/
theorem rotateLeft_eq_rotateLeftAux_of_lt {x : BitVec w} {r : Nat} (hr : r < w) :
    x.rotateLeft r = x.rotateLeftAux r := by
  simp only [rotateLeft, Nat.mod_eq_of_lt hr]


/--
Accessing bits in `x.rotateLeft r` the range `[0, r)` is equal to
accessing bits `x` in the range `[w - r, w)`.

Proof by example:
Let x := <6 5 4 3 2 1 0> : BitVec 7.
x.rotateLeft 2 = (<6 5 | 4 3 2 1 0>).rotateLeft 2 = <3 2 1 0 | 6 5>

(x.rotateLeft 2).getLsbD ⟨i, i < 2⟩
= <3 2 1 0 | 6 5>.getLsbD ⟨i, i < 2⟩
= <6 5>[i]
= <6 5 | 4 3 2 1 0>[i + len(<4 3 2 1 0>)]
= <6 5 | 4 3 2 1 0>[i + 7 - 2]
-/
theorem getLsbD_rotateLeftAux_of_le {x : BitVec w} {r : Nat} {i : Nat} (hi : i < r) :
    (x.rotateLeftAux r).getLsbD i = x.getLsbD (w - r + i) := by
  rw [rotateLeftAux, getLsbD_or, getLsbD_ushiftRight]
  simp; omega

/--
Accessing bits in `x.rotateLeft r` the range `[r, w)` is equal to
accessing bits `x` in the range `[0, w - r)`.

Proof by example:
Let x := <6 5 4 3 2 1 0> : BitVec 7.
x.rotateLeft 2 = (<6 5 | 4 3 2 1 0>).rotateLeft 2 = <3 2 1 0 | 6 5>

(x.rotateLeft 2).getLsbD ⟨i, i ≥ 2⟩
= <3 2 1 0 | 6 5>.getLsbD ⟨i, i ≥ 2⟩
= <3 2 1 0>[i - 2]
= <6 5 | 3 2 1 0>[i - 2]

Intuitively, grab the full width (7), then move the marker `|` by `r` to the right `(-2)`
Then, access the bit at `i` from the right `(+i)`.
 -/
theorem getLsbD_rotateLeftAux_of_geq {x : BitVec w} {r : Nat} {i : Nat} (hi : i ≥ r) :
    (x.rotateLeftAux r).getLsbD i = (decide (i < w) && x.getLsbD (i - r)) := by
  rw [rotateLeftAux, getLsbD_or]
  suffices (x >>> (w - r)).getLsbD i = false by
    have hiltr : decide (i < r) = false := by
      simp [hi]
    simp [getLsbD_shiftLeft, Bool.or_false, hi, hiltr, this]
  simp only [getLsbD_ushiftRight]
  apply getLsbD_ge
  omega

/-- When `r < w`, we give a formula for `(x.rotateRight r).getLsbD i`. -/
theorem getLsbD_rotateLeft_of_le {x : BitVec w} {r i : Nat} (hr: r < w) :
    (x.rotateLeft r).getLsbD i =
      cond (i < r)
      (x.getLsbD (w - r + i))
      (decide (i < w) && x.getLsbD (i - r)) := by
  · rw [rotateLeft_eq_rotateLeftAux_of_lt hr]
    by_cases h : i < r
    · simp [h, getLsbD_rotateLeftAux_of_le h]
    · simp [h, getLsbD_rotateLeftAux_of_geq <| Nat.ge_of_not_lt h]

@[simp]
theorem getLsbD_rotateLeft {x : BitVec w} {r i : Nat}  :
    (x.rotateLeft r).getLsbD i =
      cond (i < r % w)
      (x.getLsbD (w - (r % w) + i))
      (decide (i < w) && x.getLsbD (i - (r % w))) := by
  rcases w with ⟨rfl, w⟩
  · simp
  · rw [← rotateLeft_mod_eq_rotateLeft, getLsbD_rotateLeft_of_le (Nat.mod_lt _ (by omega))]

/-! ## Rotate Right -/

/--
Accessing bits in `x.rotateRight r` the range `[0, w-r)` is equal to
accessing bits `x` in the range `[r, w)`.

Proof by example:
Let x := <6 5 4 3 2 1 0> : BitVec 7.
x.rotateRight 2 = (<6 5 4 3 2 | 1 0>).rotateRight 2 = <1 0 | 6 5 4 3 2>

(x.rotateLeft 2).getLsbD ⟨i, i ≤ 7 - 2⟩
= <1 0 | 6 5 4 3 2>.getLsbD ⟨i, i ≤ 7 - 2⟩
= <6 5 4 3 2>.getLsbD i
= <6 5 4 3 2 | 1 0>[i + 2]
-/
theorem getLsbD_rotateRightAux_of_le {x : BitVec w} {r : Nat} {i : Nat} (hi : i < w - r) :
    (x.rotateRightAux r).getLsbD i = x.getLsbD (r + i) := by
  rw [rotateRightAux, getLsbD_or, getLsbD_ushiftRight]
  suffices (x <<< (w - r)).getLsbD i = false by
    simp only [this, Bool.or_false]
  simp only [getLsbD_shiftLeft, Bool.and_eq_false_imp, Bool.and_eq_true, decide_eq_true_eq,
    Bool.not_eq_true', decide_eq_false_iff_not, Nat.not_lt, and_imp]
  omega

/--
Accessing bits in `x.rotateRight r` the range `[w-r, w)` is equal to
accessing bits `x` in the range `[0, r)`.

Proof by example:
Let x := <6 5 4 3 2 1 0> : BitVec 7.
x.rotateRight 2 = (<6 5 4 3 2 | 1 0>).rotateRight 2 = <1 0 | 6 5 4 3 2>

(x.rotateLeft 2).getLsbD ⟨i, i ≥ 7 - 2⟩
= <1 0 | 6 5 4 3 2>.getLsbD ⟨i, i ≤ 7 - 2⟩
= <1 0>.getLsbD (i - len(<6 5 4 3 2>)
= <6 5 4 3 2 | 1 0> (i - len<6 4 4 3 2>)
 -/
theorem getLsbD_rotateRightAux_of_geq {x : BitVec w} {r : Nat} {i : Nat} (hi : i ≥ w - r) :
    (x.rotateRightAux r).getLsbD i = (decide (i < w) && x.getLsbD (i - (w - r))) := by
  rw [rotateRightAux, getLsbD_or]
  suffices (x >>> r).getLsbD i = false by
    simp only [this, getLsbD_shiftLeft, Bool.false_or]
    by_cases hiw : i < w
    <;> simp [hiw, hi]
  simp only [getLsbD_ushiftRight]
  apply getLsbD_ge
  omega

/-- `rotateRight` equals the bit fiddling definition of `rotateRightAux` when the rotation amount is
smaller than the bitwidth. -/
theorem rotateRight_eq_rotateRightAux_of_lt {x : BitVec w} {r : Nat} (hr : r < w) :
    x.rotateRight r = x.rotateRightAux r := by
  simp only [rotateRight, Nat.mod_eq_of_lt hr]

/-- rotateRight is invariant under `mod` by the bitwidth. -/
@[simp]
theorem rotateRight_mod_eq_rotateRight {x : BitVec w} {r : Nat} :
    x.rotateRight (r % w) = x.rotateRight r := by
  simp only [rotateRight, Nat.mod_mod]

/-- When `r < w`, we give a formula for `(x.rotateRight r).getLsb i`. -/
theorem getLsbD_rotateRight_of_le {x : BitVec w} {r i : Nat} (hr: r < w) :
    (x.rotateRight r).getLsbD i =
      cond (i < w - r)
      (x.getLsbD (r + i))
      (decide (i < w) && x.getLsbD (i - (w - r))) := by
  · rw [rotateRight_eq_rotateRightAux_of_lt hr]
    by_cases h : i < w - r
    · simp [h, getLsbD_rotateRightAux_of_le h]
    · simp [h, getLsbD_rotateRightAux_of_geq <| Nat.le_of_not_lt h]

@[simp]
theorem getLsbD_rotateRight {x : BitVec w} {r i : Nat} :
    (x.rotateRight r).getLsbD i =
      cond (i < w - (r % w))
      (x.getLsbD ((r % w) + i))
      (decide (i < w) && x.getLsbD (i - (w - (r % w)))) := by
  rcases w with ⟨rfl, w⟩
  · simp
  · rw [← rotateRight_mod_eq_rotateRight, getLsbD_rotateRight_of_le (Nat.mod_lt _ (by omega))]

/- ## twoPow -/

@[simp, bv_toNat]
theorem toNat_twoPow (w : Nat) (i : Nat) : (twoPow w i).toNat = 2^i % 2^w := by
  rcases w with rfl | w
  · simp [Nat.mod_one, toNat_of_zero_length]
  · simp only [twoPow, toNat_shiftLeft, toNat_ofNat]
    have h1 : 1 < 2 ^ (w + 1) := Nat.one_lt_two_pow (by omega)
    rw [Nat.mod_eq_of_lt h1, Nat.shiftLeft_eq, Nat.one_mul]

@[simp]
theorem getLsbD_twoPow (i j : Nat) : (twoPow w i).getLsbD j = ((i < w) && (i = j)) := by
  rcases w with rfl | w
  · simp
  · simp only [twoPow, getLsbD_shiftLeft, getLsbD_ofNat]
    by_cases hj : j < i
    · simp only [hj, decide_True, Bool.not_true, Bool.and_false, Bool.false_and, Bool.false_eq,
      Bool.and_eq_false_imp, decide_eq_true_eq, decide_eq_false_iff_not]
      omega
    · by_cases hi : Nat.testBit 1 (j - i)
      · obtain hi' := Nat.testBit_one_eq_true_iff_self_eq_zero.mp hi
        have hij : j = i := by omega
        simp_all
      · have hij : i ≠ j := by
          intro h; subst h
          simp at hi
        simp_all

theorem and_twoPow (x : BitVec w) (i : Nat) :
    x &&& (twoPow w i) = if x.getLsbD i then twoPow w i else 0#w := by
  ext j
  simp only [getLsbD_and, getLsbD_twoPow]
  by_cases hj : i = j <;> by_cases hx : x.getLsbD i <;> simp_all

theorem twoPow_and (x : BitVec w) (i : Nat) :
    (twoPow w i) &&& x = if x.getLsbD i then twoPow w i else 0#w := by
  rw [BitVec.and_comm, and_twoPow]

@[simp]
theorem mul_twoPow_eq_shiftLeft (x : BitVec w) (i : Nat) :
    x * (twoPow w i) = x <<< i := by
  apply eq_of_toNat_eq
  simp only [toNat_mul, toNat_twoPow, toNat_shiftLeft, Nat.shiftLeft_eq]
  by_cases hi : i < w
  · have hpow : 2^i < 2^w := Nat.pow_lt_pow_of_lt (by omega) (by omega)
    rw [Nat.mod_eq_of_lt hpow]
  · have hpow : 2 ^ i % 2 ^ w = 0 := by
      rw [Nat.mod_eq_zero_of_dvd]
      apply Nat.pow_dvd_pow 2 (by omega)
    simp [Nat.mul_mod, hpow]

theorem twoPow_zero {w : Nat} : twoPow w 0 = 1#w := by
  apply eq_of_toNat_eq
  simp

@[simp]
theorem getLsbD_one {w i : Nat} : (1#w).getLsbD i = (decide (0 < w) && decide (0 = i)) := by
  rw [← twoPow_zero, getLsbD_twoPow]

/- ### zeroExtend, truncate, and bitwise operations -/

/--
When the `(i+1)`th bit of `x` is false,
keeping the lower `(i + 1)` bits of `x` equals keeping the lower `i` bits.
-/
theorem zeroExtend_truncate_succ_eq_zeroExtend_truncate_of_getLsbD_false
  {x : BitVec w} {i : Nat} (hx : x.getLsbD i = false) :
    zeroExtend w (x.truncate (i + 1)) =
      zeroExtend w (x.truncate i) := by
  ext k
  simp only [getLsbD_zeroExtend, Fin.is_lt, decide_True, Bool.true_and, getLsbD_or, getLsbD_and]
  by_cases hik : i = k
  · subst hik
    simp [hx]
  · by_cases hik' : k < i + 1 <;> simp [hik'] <;> omega

/--
When the `(i+1)`th bit of `x` is true,
keeping the lower `(i + 1)` bits of `x` equalsk eeping the lower `i` bits
and then performing bitwise-or with `twoPow i = (1 << i)`,
-/
theorem zeroExtend_truncate_succ_eq_zeroExtend_truncate_or_twoPow_of_getLsbD_true
    {x : BitVec w} {i : Nat} (hx : x.getLsbD i = true) :
    zeroExtend w (x.truncate (i + 1)) =
      zeroExtend w (x.truncate i) ||| (twoPow w i) := by
  ext k
  simp only [getLsbD_zeroExtend, Fin.is_lt, decide_True, Bool.true_and, getLsbD_or, getLsbD_and]
  by_cases hik : i = k
  · subst hik
    simp [hx]
  · by_cases hik' : k < i + 1 <;> simp [hik, hik'] <;> omega

/-- Bitwise and of `(x : BitVec w)` with `1#w` equals zero extending `x.lsb` to `w`. -/
theorem and_one_eq_zeroExtend_ofBool_getLsbD {x : BitVec w} :
    (x &&& 1#w) = zeroExtend w (ofBool (x.getLsbD 0)) := by
  ext i
  simp only [getLsbD_and, getLsbD_one, getLsbD_zeroExtend, Fin.is_lt, decide_True, getLsbD_ofBool,
    Bool.true_and]
  by_cases h : (0 = (i : Nat)) <;> simp [h] <;> omega

@[simp]
theorem replicate_zero_eq {x : BitVec w} : x.replicate 0 = 0#0 := by
  simp [replicate]

@[simp]
theorem replicate_succ_eq {x : BitVec w} :
    x.replicate (n + 1) =
    (x ++ replicate n x).cast (by rw [Nat.mul_succ]; omega) := by
  simp [replicate]

/--
If a number `w * n ≤ i < w * (n + 1)`, then `i - w * n` equals `i % w`.
This is true by subtracting `w * n` from the inequality, giving
`0 ≤ i - w * n < w`, which uniquely identifies `i % w`.
-/
private theorem Nat.sub_mul_eq_mod_of_lt_of_le (hlo : w * n ≤ i) (hhi : i < w * (n + 1)) :
    i - w * n = i % w := by
  rw [Nat.mod_def]
  congr
  symm
  apply Nat.div_eq_of_lt_le
    (by rw [Nat.mul_comm]; omega)
    (by rw [Nat.mul_comm]; omega)

@[simp]
theorem getLsbD_replicate {n w : Nat} (x : BitVec w) :
    (x.replicate n).getLsbD i =
    (decide (i < w * n) && x.getLsbD (i % w)) := by
  induction n generalizing x
  case zero => simp
  case succ n ih =>
    simp only [replicate_succ_eq, getLsbD_cast, getLsbD_append]
    by_cases hi : i < w * (n + 1)
    · simp only [hi, decide_True, Bool.true_and]
      by_cases hi' : i < w * n
      · simp [hi', ih]
      · simp only [hi', decide_False, cond_false]
        rw [Nat.sub_mul_eq_mod_of_lt_of_le] <;> omega
    · rw [Nat.mul_succ] at hi ⊢
      simp only [show ¬i < w * n by omega, decide_False, cond_false, hi, Bool.false_and]
      apply BitVec.getLsbD_ge (x := x) (i := i - w * n) (ge := by omega)

/-! ### intMin -/

/-- The bitvector of width `w` that has the smallest value when interpreted as an integer. -/
def intMin (w : Nat) := twoPow w (w - 1)

theorem getLsbD_intMin (w : Nat) : (intMin w).getLsbD i = decide (i + 1 = w) := by
  simp only [intMin, getLsbD_twoPow, boolToPropSimps]
  omega

@[simp, bv_toNat]
theorem toNat_intMin : (intMin w).toNat = 2 ^ (w - 1) % 2 ^ w := by
  simp [intMin]

@[simp]
theorem neg_intMin {w : Nat} : -intMin w = intMin w := by
  by_cases h : 0 < w
  · simp [bv_toNat, h]
  · simp only [Nat.not_lt, Nat.le_zero_eq] at h
    simp [bv_toNat, h]

/-! ### intMax -/

/-- The bitvector of width `w` that has the largest value when interpreted as an integer. -/
def intMax (w : Nat) := (twoPow w (w - 1)) - 1

@[simp, bv_toNat]
theorem toNat_intMax : (intMax w).toNat = 2 ^ (w - 1) - 1 := by
  simp only [intMax]
  by_cases h : w = 0
  · simp [h]
  · have h' : 0 < w := by omega
    rw [toNat_sub, toNat_twoPow, ← Nat.sub_add_comm (by simpa [h'] using Nat.one_le_two_pow),
      Nat.add_sub_assoc (by simpa [h'] using Nat.one_le_two_pow),
      Nat.two_pow_pred_mod_two_pow h', ofNat_eq_ofNat, toNat_ofNat, Nat.one_mod_two_pow h',
      Nat.add_mod_left, Nat.mod_eq_of_lt]
    have := Nat.two_pow_pred_lt_two_pow h'
    have := Nat.two_pow_pos w
    omega

@[simp]
theorem getLsbD_intMax (w : Nat) : (intMax w).getLsbD i = decide (i + 1 < w) := by
  rw [← testBit_toNat, toNat_intMax, Nat.testBit_two_pow_sub_one, decide_eq_decide]
  omega

@[simp] theorem intMax_add_one {w : Nat} : intMax w + 1#w = intMin w := by
  simp only [toNat_eq, toNat_intMax, toNat_add, toNat_intMin, toNat_ofNat, Nat.add_mod_mod]
  by_cases h : w = 0
  · simp [h]
  · rw [Nat.sub_add_cancel (Nat.two_pow_pos (w - 1)), Nat.two_pow_pred_mod_two_pow (by omega)]

end BitVec
