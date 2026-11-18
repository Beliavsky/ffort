implicit none
integer::undefined
outer: do while(kind(undefined)==8)
print '(i0)',undefined
end do outer
print '(a)','FALSE'
end
