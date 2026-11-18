program elemental_actions
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
call wrapper(aa)
print *,aa
contains
pure subroutine wrapper(xx)
integer,intent(inout)::xx(:)
call bump(xx)
end subroutine wrapper
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
