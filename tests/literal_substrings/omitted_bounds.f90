program p
implicit none
integer::i
i=2
if ('abcdef'(:i)/='ab'.or.'abcdef'(i:)/='bcdef'.or.'abcdef'(:)/='abcdef') error stop 1
print *, 'omitted bounds' 
end program
