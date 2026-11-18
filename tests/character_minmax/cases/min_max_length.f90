program p
implicit none

print *,len(min(repeat('x',65536),'a')),len_trim(min(repeat('x',65536),'a'))
end program
