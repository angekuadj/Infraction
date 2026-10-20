package ci.circulation.api.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class FileStorageService {

    private final Path uploadDir;

    public FileStorageService(@Value("${app.upload-dir:uploads}") String uploadDir) {
        this.uploadDir = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.uploadDir);
        } catch (IOException e) {
            throw new IllegalStateException("Impossible de créer le dossier d'upload: " + this.uploadDir, e);
        }
    }

    public Path getUploadDir() {
        return uploadDir;
    }

    /** Enregistre un fichier et retourne son nom de fichier stocké. */
    public String store(MultipartFile file) {
        if (file == null || file.isEmpty()) return null;
        String original = file.getOriginalFilename() == null ? "" : file.getOriginalFilename();
        String ext = "";
        int dot = original.lastIndexOf('.');
        if (dot >= 0 && dot < original.length() - 1) {
            ext = original.substring(dot).toLowerCase();
        }
        String name = UUID.randomUUID().toString().replace("-", "") + ext;
        try {
            file.transferTo(uploadDir.resolve(name));
        } catch (IOException e) {
            throw new IllegalStateException("Échec de l'enregistrement du fichier", e);
        }
        return name;
    }
}
