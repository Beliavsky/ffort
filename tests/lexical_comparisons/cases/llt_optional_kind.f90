program p
call f()
contains
subroutine f(a)
character(*),optional,intent(in)::a
print *,kind(llt(a,"x"))
end subroutine
end program
