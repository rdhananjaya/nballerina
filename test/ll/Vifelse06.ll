declare void @_Bio__println (i64)
define void @_B_main () {
  %_0 = alloca i1, align 8
  %_1 = alloca i1, align 8
  %_2 = alloca i1, align 8
  %_3 = alloca i1, align 8
  call void @_B_printIfFalse (i1 1)
  store i1 0, i1* %_0, align 8
  call void @_B_printIfFalse (i1 0)
  store i1 0, i1* %_1, align 8
  call void @_B_printIfTrue (i1 1)
  store i1 0, i1* %_2, align 8
  call void @_B_printIfTrue (i1 0)
  store i1 0, i1* %_3, align 8
  ret void
}
define internal void @_B_printIfFalse (i1 %_0) {
  %b = alloca i1, align 8
  %_1 = alloca i1, align 8
  store i1 %_0, i1* %b, align 8
  %_2 = load i1, i1* %b, align 8
  br i1 %_2, label %L1, label %L2
L1:
  br label %L3
L2:
  call void @_Bio__println (i64 0)
  store i1 0, i1* %_1, align 8
  br label %L3
L3:
  ret void
}
define internal void @_B_printIfTrue (i1 %_0) {
  %b = alloca i1, align 8
  %_1 = alloca i1, align 8
  store i1 %_0, i1* %b, align 8
  %_2 = load i1, i1* %b, align 8
  br i1 %_2, label %L1, label %L2
L1:
  call void @_Bio__println (i64 1)
  store i1 0, i1* %_1, align 8
  br label %L2
L2:
  ret void
}