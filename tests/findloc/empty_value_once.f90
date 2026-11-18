module m
integer::calls=0
contains
impure elemental integer function wanted()
calls=calls+1
wanted=2
end function
end module
program p
use m
integer::a(0)
print *,findloc(a,wanted(),dim=1)
print *,calls
end program
