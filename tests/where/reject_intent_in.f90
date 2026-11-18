program p
contains
subroutine f(a)
integer,intent(in)::a(:)
where(a>0) a=1
end subroutine
end program
