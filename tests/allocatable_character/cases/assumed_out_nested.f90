program p
character(3),allocatable::a(:)
character(:),allocatable::b(:)
call fill(a)
print '(i2,1x,i2,1x,2a4)',len(a),size(a),a
allocate(character(len=4)::b(-1:0))
b='hello'
print '(i2,1x,i2,1x,2a5)',len(b),lbound(b,1),b
b=[character(2)::'aa','bb','cc']
print '(i2,1x,i2,1x,3a3)',len(b),size(b),b
call dfill(b)
print '(i2,1x,i2,1x,2a6)',len(b),lbound(b,1),b
contains
subroutine fill(x)
character(*),allocatable,intent(out)::x(:)
allocate(x(-1:0))
x=['abc','def']
end subroutine
subroutine dfill(x)
character(:),allocatable,intent(out)::x(:)
allocate(character(5)::x(4:5))
x='test'
end subroutine
end program
