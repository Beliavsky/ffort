module m
implicit none
contains
subroutine tick()
integer(8),save::i=2147483648_8
real(8),save::x=0.5_8
logical,save::flag=.false.
character(len=4),save::word='AB'
i=i+1_8
x=x+0.25_8
flag=.not.flag
word=word(2:)//'x'
print *,i,x,flag,word
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
