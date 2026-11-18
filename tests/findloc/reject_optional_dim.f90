program p
contains
subroutine f(a,d)
integer,intent(in)::a(:)
integer,optional,intent(in)::d
print *,findloc(a,1,dim=d)
end subroutine
end program
