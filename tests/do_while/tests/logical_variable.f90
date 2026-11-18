implicit none
logical::more
integer::i
i=0
more=.true.
do while(more)
i=i+1
more=i<3
end do
print "(i0)",i
end
