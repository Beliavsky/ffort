implicit none
character(4) :: x(2,2), y(-1:0,2,2)
x='abcd'
y='wxyz'
x(2,1)(2:3)='PQ'
y(0,2,1)(:2)=x(2,1)(2:3)
print '(a)',x(2,1)(:),y(0,2,1)(:),y(-1,1,1)(2:)
end
