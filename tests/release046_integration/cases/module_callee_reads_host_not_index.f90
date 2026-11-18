module values
implicit none
integer::i
contains
integer function observe()
observe=i
end function
subroutine show()
integer::a(3)
i=40
a=[(i+observe(),i=1,3)]
print '(4i4)',a,i
end subroutine
end module
program p
use values,only:show
implicit none
call show()
end program
