program p
implicit none

call build()
contains
subroutine build(k)
integer,optional,intent(in)::k
integer::a(3)
a=[(k,k=1,3)]
print '(3i3,l2,2i3)',a,present(k),lbound(a),ubound(a)
end subroutine
end program
