program p
character(4)::a
a='abcd'
call bump(a)
print '(a)',a
contains
subroutine bump(x)
character(*),intent(in out)::x
x(2:3)='XY'
end subroutine
end program
