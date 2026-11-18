program p
call f()
contains
subroutine f(a)
character(*),optional,intent(in)::a
print *,kind(lge(a,"x"))
end subroutine
end program
