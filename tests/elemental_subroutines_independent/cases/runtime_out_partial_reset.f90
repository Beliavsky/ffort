program elemental_actions
implicit none
integer::aa(3)
aa=7
call keep(aa)
print *,aa
contains
elemental subroutine keep(xx)
integer,intent(out)::xx
return
end subroutine keep

end program
