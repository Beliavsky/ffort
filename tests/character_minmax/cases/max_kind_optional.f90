program p
call f()
contains
subroutine f(a)
character(*),optional,intent(in)::a
print *,kind(max(a,"x"))
end subroutine
end program
