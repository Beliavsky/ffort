implicit none
integer::i,n,j
i=0
n=0
outer: do while(i<3)
i=i+1
do j=1,2
n=n+1
cycle outer
end do
end do outer
print "(i0)",n
end
