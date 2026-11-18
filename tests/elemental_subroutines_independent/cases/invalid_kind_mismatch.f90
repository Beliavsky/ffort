program elemental_actions
implicit none
real(8)::aa(2)
print *,991
aa=2.0d0
call bump(aa)
contains
elemental subroutine bump(xx)
real,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
