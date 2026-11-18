program p
implicit none
integer(8)::a(2,2)
logical::l(2,2)
a=reshape(pack([9007199254740993_8,-9007199254740995_8],.true.),[2,2], &
pad=pack([9223372036854775807_8,-9223372036854775807_8],.true.),order=[2,1])
l=reshape(pack([.true.,.false.,.true.],.true.),[2,2],pad=[.false.],order=[2,1])
print *,a
print *,pack(l,.true.)
end program
