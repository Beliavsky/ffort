program elemental_actions
implicit none
integer::aa(3)
aa(1)=7
call keep(aa)
print *,aa(1)
contains
elemental subroutine keep(xx)
integer,intent(inout)::xx
return
end subroutine keep

end program
