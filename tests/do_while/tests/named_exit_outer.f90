implicit none
integer::i,n,j
i=0
outer: do while(.true.)
i=i+1
do j=1,2
exit outer
end do
end do outer
j=4
print "(i0)",i+j
end
