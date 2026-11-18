program p
call take('abc'(1:2))
contains
subroutine take(s)
character(*),intent(out)::s
s='zz'
end subroutine
end program
