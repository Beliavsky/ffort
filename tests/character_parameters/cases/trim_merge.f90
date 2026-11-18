implicit none
character(*),parameter::a=merge(trim("ab  "),trim("cd "),.true.)
character(*),parameter::b(2)=merge(["ef","gh"],trim("xy "),[.false.,.true.])
print '(a)',a,b
end
