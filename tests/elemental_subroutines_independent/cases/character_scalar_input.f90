program elemental_actions
implicit none
integer::aa(2)
call tag(aa,"item")
print *,aa
contains
impure elemental subroutine tag(xx,label)
integer,intent(out)::xx
character(len=*),intent(in)::label
print *,label
xx=2
end subroutine tag

end program
