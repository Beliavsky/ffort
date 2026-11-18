program p
implicit none
integer::a(2)
call fill(2,a)
contains
subroutine fill(i,a)
integer,intent(in)::i
integer,intent(out)::a(:)
forall(i=1:2) a(i)=i
end subroutine
end program
