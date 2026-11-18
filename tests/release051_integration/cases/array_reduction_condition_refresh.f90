implicit none
integer::a(3),n
a=[0,1,2];n=0
do while(any(a<2))
a=a+1
n=n+1
end do
print '(i0,3(1x,i0))',n,a
end
