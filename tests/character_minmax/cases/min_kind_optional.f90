program p
call f()
contains
subroutine f(a)
character(*),optional,intent(in)::a
print *,kind(min(a,"x"))
end subroutine
end program
