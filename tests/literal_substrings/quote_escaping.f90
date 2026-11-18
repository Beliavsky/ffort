program p
implicit none
integer::i
i=2
if ('a''b'(i:i)/="'".or.'a''b'(2:3)/="'b") error stop 1
if ("a""b"(i:)/='"b') error stop 2
print *, 'escaped quotes' 
end program
