implicit none
integer::i
i=0
outer: do while(i<3)
i=i+1
enddo outer
print "(i0)",i
end
