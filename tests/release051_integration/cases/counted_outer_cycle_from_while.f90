implicit none
integer::i,j,n
n=0
outer: do i=1,3
j=0
do while(j<2)
j=j+1
n=n+i
cycle outer
end do
end do outer
i=9
print '(i0,1x,i0)',i,n
end
