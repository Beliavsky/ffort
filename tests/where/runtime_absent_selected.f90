program p
integer::a(2)=1
call f(a)
contains
subroutine f(a,x)
integer,intent(inout)::a(:)
integer,optional,intent(in)::x
where(a>0) a=x
end subroutine
end program
