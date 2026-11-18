implicit none
integer::while,i,n
i=0;n=0
do while(i<2)
do while=1,3
n=n+while
end do
i=i+1
end do
print '(i0,1x,i0,1x,i0)',i,while,n
end
