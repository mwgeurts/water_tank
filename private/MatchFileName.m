function [a, b, c] = MatchFileName(name, reference)


name = regexprep(name,'(\d+)E','$1MeV ');
name = regexprep(name,'(\d+)X','$1MV ');
name = regexprep(name,'(\d+)FFF','$1MVFFF ');
name = regexprep(name,'(\d+)x(\d+)','$1 x $2');
name = regexprep(name,'(\d+)fs','$1 x $1');

nameparts = strsplit(name, {' ','_','-','.'});
m = 0;
a = 0;
b = 0;
c = 0;
for i = 1:length(reference)
    for j = 1:length(reference{i}.energies)
        for k = 1:length(reference{i}.energies{i}.fields)
            n = 0;
            for l = 1:length(nameparts)
                n = n + sum(strcmpi(nameparts{l}, ...
                    horzcat(strsplit(reference{i}...
                    .machine), strrep(reference{i}.energies{j}...
                    .energy, ' ', ''), strsplit(reference{i}.energies{j}...
                    .fields{k}))));
            end
            if n > m
                m = n;
                a = i;
                b = j;
                c = k;
            end
        end
    end
end