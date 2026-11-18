program elemental_actions
implicit none
integer::aa
aa=2
print *,compute(aa)
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
call emit(xx)
rr=xx
end function compute
 subroutine emit(xx)
integer,intent(in)::xx
print *,xx
end subroutine emit

end program
