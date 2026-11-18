print*,"max consective =",max_consecutive([1,1,0,0,0,1,1,1,0]>0)
print*,"max consective =",max_consecutive([1,1,1]>0)
print*,"max consective =",max_consecutive([0,0,0]>0)
allocate (xchar(0))
call set_alloc(concat_char_vec(["dog","cat"],["four","five","zero"]),char_vec)
print*,len(char_vec),char_vec
call set_alloc(concat_char_vec(xchar,["four","five","zero"]),char_vec)
print*,len(char_vec),char_vec
call set_alloc(concat_char_vec(["dog","cat"],xchar),char_vec)
print*,len(char_vec),char_vec
deallocate (char_vec)
allocate (char_vec(0))
